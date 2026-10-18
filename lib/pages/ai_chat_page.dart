// AI 对话查询页：用户用自然语言询问账目，AI 调用只读工具查询后以图表 / 列表 / 卡片 +
// Markdown 文字作答。全屏聊天页，消息气泡 + 底部输入框 + 清空历史。
//
// 网络传输默认使用结构化 Agent SSE；debug transport 供测试注入，避免真实网络。
import 'dart:async';

import 'package:anchored_menu/anchored_menu.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../app/ai/ai_agent_engine.dart';
import '../app/ai/ai_agent_event.dart';
import '../app/ai/ai_agent_message.dart';
import '../app/ai/ai_agent_step.dart';
import '../app/ai/ai_answer_provenance.dart';
import '../app/ai/ai_capabilities.dart';
import '../app/ai/ai_client.dart';
import '../app/ai/ai_query_tool.dart';
import '../app/ai/ai_settings.dart';
import '../app/ai/ai_tool_presentation.dart';
import '../app/app_theme.dart';
import '../app/common_widgets.dart';
import '../app/models.dart';
import '../app/veri_fin_controller.dart';
import '../app/veri_fin_scope.dart';
import '../l10n/app_localizations.dart';
import 'ai_agent_step_view.dart';
import 'ai_result_view.dart';
import 'ai_settings_page.dart';

enum _Role { user, assistant }

enum _MsgStatus { streaming, done, error }

/// 一条聊天消息的 UI 状态。助手消息可同时含若干结果卡片与流式 Markdown 文本。
class _ChatMessage {
  _ChatMessage({
    required this.role,
    required this.bookId,
    required this.bookName,
    required this.baseCurrencyCode,
    required this.moneyCodeDisplay,
    this.text = '',
    this.status = _MsgStatus.done,
    List<AiResultDisplay>? displays,
    List<AiAgentStep>? steps,
    this.sourceUserInput = '',
  }) : displays = displays ?? <AiResultDisplay>[],
       steps = steps ?? <AiAgentStep>[];

  final _Role role;
  final String bookId;
  final String bookName;
  final String baseCurrencyCode;
  final MoneyCodeDisplay moneyCodeDisplay;
  final String sourceUserInput;
  String text;
  final List<AiResultDisplay> displays;
  final List<AiAgentStep> steps;
  _MsgStatus status;
  String? errorText;
  int successfulToolCalls = 0;
  AiAnswerProvenance? provenance;
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({
    super.key,
    this.debugTransport,
    this.debugCompleteTransport,
  });

  final AiAgentStreamTransport? debugTransport;
  final AiAgentCompleteTransport? debugCompleteTransport;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final AiAgentEngine _engine = AiAgentEngine(tools: buildAiQueryTools());
  String? _selectedBookId;
  _ChatMessage? _activeAssistant;
  AiAgentCancellation? _activeCancellation;
  int _requestSerial = 0;
  bool _streaming = false;

  @override
  void initState() {
    super.initState();
    // 输入内容变化时刷新发送按钮的可用态（空内容不可发送）。
    _input.addListener(_onInputChanged);
    _inputFocus.addListener(_onInputFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedBookId ??= VeriFinScope.of(context).activeBook.id;
  }

  void _onInputChanged() => setState(() {});

  void _onInputFocusChanged() => setState(() {});

  @override
  void dispose() {
    _requestSerial += 1;
    _activeCancellation?.cancel();
    _input.removeListener(_onInputChanged);
    _inputFocus.removeListener(_onInputFocusChanged);
    _inputFocus.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _canSend => !_streaming && _input.text.trim().isNotEmpty;

  LedgerBook _bookForScope(VeriFinController scope) {
    return scope.ledgerBooks
            .where((book) => book.id == _selectedBookId)
            .firstOrNull ??
        scope.activeBook;
  }

  void _selectBook(String bookId) {
    if (bookId == _selectedBookId) {
      return;
    }
    setState(() => _selectedBookId = bookId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 从已完成的历史消息构建给模型的上下文（不含正在流式的这条）。
  List<AiTextMessage> _priorMessages() {
    return <AiTextMessage>[
      for (final m in _messages)
        if (m.status == _MsgStatus.done && m.text.trim().isNotEmpty)
          AiTextMessage(
            role: m.role == _Role.user
                ? AiMessageRole.user
                : AiMessageRole.assistant,
            content: m.text.trim(),
          ),
    ];
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _streaming) {
      return;
    }
    final scope = VeriFinScope.of(context);
    final l10n = AppLocalizations.of(context);
    final book = _bookForScope(scope);
    final moneyDisplay = scope.moneyCodeDisplayForBook(book.id);
    final prior = _priorMessages();
    final snapshot = scope.aiLedgerSnapshotForBook(book.id);
    final context0 = AiToolContext(
      ledger: snapshot,
      now: snapshot.capturedAt,
      l10n: l10n,
      // 摘要句与结果卡片要跟界面上金额的单位口径一致：单币种账本隐藏单位时，
      // 摘要也不能出现币种代码，否则模型会照着写出与卡片矛盾的「合计 CNY 4,300」。
      currencyDisplay: moneyDisplay,
    );
    final settings = scope.aiSettings;
    final transport =
        widget.debugTransport ??
        (List<AiAgentMessage> messages, List<Map<String, Object?>> tools) =>
            aiAgentStream(settings: settings, messages: messages, tools: tools);
    final completeTransport =
        widget.debugCompleteTransport ??
        (List<AiAgentMessage> messages, List<Map<String, Object?>> tools) =>
            aiAgentComplete(
              settings: settings,
              messages: messages,
              tools: tools,
            );
    final capability = scope.aiCapabilityProfile;
    final mode = resolveAiAgentMode(settings: settings, capability: capability);

    final assistant = _ChatMessage(
      role: _Role.assistant,
      bookId: book.id,
      bookName: book.name,
      baseCurrencyCode: book.baseCurrencyCode,
      moneyCodeDisplay: moneyDisplay,
      status: _MsgStatus.streaming,
      sourceUserInput: text,
    );
    final requestId = ++_requestSerial;
    final cancellation = AiAgentCancellation();
    _activeCancellation = cancellation;
    setState(() {
      _input.clear();
      _selectedBookId = book.id;
      _messages.add(
        _ChatMessage(
          role: _Role.user,
          bookId: book.id,
          bookName: book.name,
          baseCurrencyCode: book.baseCurrencyCode,
          moneyCodeDisplay: moneyDisplay,
          text: text,
        ),
      );
      _messages.add(assistant);
      _streaming = true;
    });
    _activeAssistant = assistant;
    _scrollToBottom();

    _engine
        .run(
          mode: mode,
          streamTransport: transport,
          completeTransport: completeTransport,
          context: context0,
          priorMessages: prior,
          userInput: text,
          cancellation: cancellation,
        )
        .listen(
          (event) {
            if (!mounted || requestId != _requestSerial) {
              return;
            }
            setState(() {
              if (event is AiAgentFailed) {
                _finishRetrySteps(assistant, succeeded: false);
              } else if (event is! AiAgentRetrying) {
                _finishRetrySteps(assistant, succeeded: true);
              }
              switch (event) {
                case final AiAgentToolStarted e:
                  if (mode != AiToolCallMode.prompt &&
                      scope.aiCapabilityProfile?.matches(settings) != true) {
                    scope.setAiCapabilityProfile(
                      AiCapabilityProfile.forSettings(
                        settings: settings,
                        nativeToolCalls: AiNativeToolCapability.supported,
                      ),
                    );
                  }
                  assistant.steps.add(
                    AiAgentStep(
                      id: e.stepId,
                      toolName: e.toolName,
                      status: AiAgentStepStatus.running,
                      arguments: e.arguments,
                    ),
                  );
                case final AiAgentToolCompleted e:
                  assistant.successfulToolCalls += 1;
                  _updateStep(
                    assistant,
                    e.stepId,
                    status: AiAgentStepStatus.succeeded,
                    summary: presentAiToolResultSummary(l10n, e.result),
                  );
                  if (e.result.display != null) {
                    assistant.displays.add(e.result.display!);
                  }
                case final AiAgentToolFailed e:
                  _updateStep(
                    assistant,
                    e.stepId,
                    status: AiAgentStepStatus.failed,
                    summary: l10n.aiStepFailed,
                  );
                case final AiAgentRetrying e:
                  if (e.reason == 'protocolFallback') {
                    scope.setAiCapabilityProfile(
                      AiCapabilityProfile.forSettings(
                        settings: settings,
                        nativeToolCalls: AiNativeToolCapability.unsupported,
                      ),
                    );
                  }
                  assistant.steps.add(
                    AiAgentStep(
                      id: 'retry-${assistant.steps.length}',
                      toolName: 'agentRetry',
                      status: AiAgentStepStatus.retrying,
                      summary: e.reason,
                    ),
                  );
                case final AiAgentAnswerDelta e:
                  assistant.text += e.text;
                case final AiAgentCompleted e:
                  if (assistant.text.trim().isEmpty) {
                    assistant.text = e.answer;
                  }
                  assistant.successfulToolCalls = e.successfulToolCalls;
                  assistant.provenance = classifyAiAnswerProvenance(
                    userInput: assistant.sourceUserInput,
                    answer: assistant.text,
                    successfulToolCalls: assistant.successfulToolCalls,
                  );
                  assistant.status = _MsgStatus.done;
                case final AiAgentFailed e:
                  assistant.status = _MsgStatus.error;
                  assistant.errorText = e.error is AiException
                      ? aiErrorMessage(l10n, e.error as AiException)
                      : l10n.aiErrUnknown;
                  assistant.provenance = classifyAiAnswerProvenance(
                    userInput: assistant.sourceUserInput,
                    answer: assistant.text,
                    successfulToolCalls: assistant.successfulToolCalls,
                  );
                  scope.logger?.error(
                    'AI Agent 回答失败',
                    source: 'ai',
                    error: e.error,
                  );
              }
            });
            _scrollToBottom();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted || requestId != _requestSerial) {
              return;
            }
            setState(() {
              _finishRetrySteps(assistant, succeeded: false);
              assistant.status = _MsgStatus.error;
              assistant.errorText = error is AiException
                  ? aiErrorMessage(l10n, error)
                  : l10n.aiErrUnknown;
              assistant.provenance = classifyAiAnswerProvenance(
                userInput: assistant.sourceUserInput,
                answer: assistant.text,
                successfulToolCalls: assistant.successfulToolCalls,
              );
              _streaming = false;
              _activeAssistant = null;
              _activeCancellation = null;
            });
            scope.logger?.error('AI Agent 回答失败', source: 'ai', error: error);
            _scrollToBottom();
          },
          onDone: () {
            if (!mounted || requestId != _requestSerial) {
              return;
            }
            setState(() {
              _streaming = false;
              _activeAssistant = null;
              _activeCancellation = null;
              if (assistant.status == _MsgStatus.streaming) {
                assistant.status = _MsgStatus.done;
              }
            });
          },
          cancelOnError: true,
        );
  }

  void _stopGeneration() {
    final assistant = _activeAssistant;
    _requestSerial += 1;
    _activeAssistant = null;
    _activeCancellation?.cancel();
    _activeCancellation = null;
    setState(() {
      _streaming = false;
      assistant?.steps.removeWhere(
        (step) =>
            step.status == AiAgentStepStatus.running ||
            step.status == AiAgentStepStatus.retrying,
      );
      if (assistant?.status == _MsgStatus.streaming) {
        assistant?.status = _MsgStatus.done;
      }
      if (assistant != null) {
        assistant.provenance = classifyAiAnswerProvenance(
          userInput: assistant.sourceUserInput,
          answer: assistant.text,
          successfulToolCalls: assistant.successfulToolCalls,
        );
      }
    });
  }

  void _updateStep(
    _ChatMessage message,
    String stepId, {
    required AiAgentStepStatus status,
    required String summary,
  }) {
    final index = message.steps.indexWhere((step) => step.id == stepId);
    if (index < 0) return;
    message.steps[index] = message.steps[index].copyWith(
      status: status,
      summary: summary,
    );
  }

  void _finishRetrySteps(_ChatMessage message, {required bool succeeded}) {
    for (var index = 0; index < message.steps.length; index += 1) {
      final step = message.steps[index];
      if (step.status == AiAgentStepStatus.retrying) {
        message.steps[index] = step.copyWith(
          status: succeeded
              ? AiAgentStepStatus.succeeded
              : AiAgentStepStatus.failed,
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.aiChatClearHistory,
      message: l10n.aiChatClearMessage,
      confirmLabel: l10n.aiChatClearConfirm,
      destructive: true,
    );
    if (confirmed && mounted) {
      setState(_messages.clear);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AiSettingsPage()));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = VeriFinScope.of(context);
    final configured = scope.aiSettings.isConfigured;
    final book = _bookForScope(scope);
    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: Column(
            children: <Widget>[
              // 与收支统计等页保持一致：头部套 fromLTRB(14, 8, 14, 0) 内边距，
              // 使返回箭头/标题的位置和其它页对齐（VeriHeader 自身无横向内边距）。
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: VeriHeader(
                  title: l10n.aiChatTitle,
                  showBack: true,
                  actions: <Widget>[
                    if (configured)
                      Visibility(
                        visible: _messages.isNotEmpty,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: HeaderAction(
                          icon: Icons.delete_outline,
                          tooltip: l10n.aiChatClearCurrent,
                          onPressed: _streaming ? null : _clearHistory,
                          destructive: true,
                        ),
                      ),
                    if (configured)
                      HeaderAction(
                        icon: Icons.settings_outlined,
                        tooltip: l10n.aiSettingsTitle,
                        onPressed: _streaming ? null : _openSettings,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: configured
                    ? (_messages.isEmpty
                          ? _buildEmptyState(context, book)
                          : _buildMessageList(context))
                    : _buildUnconfigured(context),
              ),
              if (configured) _buildInputBar(context, book),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnconfigured(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: EmptyState(
        icon: Icons.smart_toy_outlined,
        title: l10n.aiChatUnconfiguredTitle,
        description: l10n.aiChatUnconfiguredHint,
        action: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AiSettingsPage()),
          ),
          icon: const Icon(Icons.settings_outlined),
          label: Text(l10n.aiChatGoConfigure),
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    final showBookLabel =
        _messages.map((message) => message.bookId).toSet().length > 1;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final retryText =
            message.status == _MsgStatus.error &&
                index > 0 &&
                _messages[index - 1].role == _Role.user
            ? _messages[index - 1].text
            : null;
        return _MessageView(
          message: message,
          showBookLabel: showBookLabel,
          onRetry: retryText == null || _streaming
              ? null
              : () async {
                  _selectedBookId = message.bookId;
                  _input.text = retryText;
                  await _send();
                },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, LedgerBook book) {
    final l10n = AppLocalizations.of(context);
    final hints = <String>[
      l10n.aiChatHintTopCategory,
      l10n.aiChatHintLargeExpense,
      l10n.aiChatHintMonthSummary,
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                l10n.aiChatEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.aiChatCurrentBook(book.name),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final hint in hints)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ActionChip(
                  avatar: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(hint),
                  onPressed: () {
                    _input.text = hint;
                    _send();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, LedgerBook book) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canSend = _canSend;
    final l10n = AppLocalizations.of(context);
    final books = VeriFinScope.of(context).ledgerBooks;
    final borderColor = _inputFocus.hasFocus
        ? theme.colorScheme.primary
        : Colors.transparent;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.58);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        key: const Key('ai_chat_composer'),
        decoration: BoxDecoration(
          color: veriElevatedSurfaceColor(theme.brightness),
          borderRadius: BorderRadius.circular(veriRadiusXl),
          border: Border.all(
            color: borderColor,
            width: _inputFocus.hasFocus ? 1.2 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: TextField(
                controller: _input,
                focusNode: _inputFocus,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onTapOutside: (_) => _inputFocus.unfocus(),
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.94),
                ),
                decoration: InputDecoration(
                  hintText: l10n.aiChatInputHint,
                  hintStyle: TextStyle(color: muted),
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: Row(
                children: <Widget>[
                  const Spacer(),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnchoredMenuChoice<String>(
                        values: books
                            .map((entry) => entry.id)
                            .toList(growable: false),
                        selected: book.id,
                        idOf: (id) => 'ai_chat_book_$id',
                        labelOf: (id) =>
                            books.firstWhere((entry) => entry.id == id).name,
                        iconOf: (_) => Icons.account_balance_wallet_outlined,
                        onSelected: _selectBook,
                        semanticLabel: l10n.aiChatChooseBook,
                        width: 232,
                        builder: (context, openMenu, menuOpen) => Semantics(
                          button: true,
                          label: l10n.aiChatChooseBook,
                          child: InkWell(
                            key: const Key('ai_chat_book_selector'),
                            borderRadius: BorderRadius.circular(999),
                            onTap: _streaming
                                ? null
                                : () {
                                    _inputFocus.unfocus();
                                    openMenu();
                                  },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 16,
                                    color: muted,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      book.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.82),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    menuOpen
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(
                    enabled: canSend,
                    streaming: _streaming,
                    onSend: _send,
                    onStop: _stopGeneration,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部操作按钮：空闲时发送；流式时原位切换为停止。
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.streaming,
    required this.onSend,
    required this.onStop,
  });

  final bool enabled;
  final bool streaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabledBg = scheme.surfaceContainerHighest;
    final disabledFg = scheme.onSurface.withValues(alpha: 0.35);
    final active = enabled || streaming;
    final l10n = AppLocalizations.of(context);
    return Material(
      key: const Key('ai_chat_send_button'),
      color: active ? scheme.onSurface : disabledBg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: streaming ? onStop : (enabled ? onSend : null),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Tooltip(
            message: streaming ? l10n.aiStopGenerating : l10n.aiSendQuestion,
            child: Icon(
              streaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
              color: active ? scheme.surface : disabledFg,
              size: streaming ? 15 : 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.message,
    required this.showBookLabel,
    this.onRetry,
  });

  final _ChatMessage message;
  final bool showBookLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (message.role == _Role.user) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (showBookLabel)
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 2, right: 4),
              child: Text(
                message.bookName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(veriRadiusLg),
                  topRight: Radius.circular(veriRadiusLg),
                  bottomLeft: Radius.circular(veriRadiusLg),
                  bottomRight: Radius.circular(veriRadiusSm),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 15.5,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showBookLabel)
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 2, left: 2),
              child: Text(
                message.bookName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final step in message.steps) AiAgentStepView(step: step),
          for (final display in message.displays) ...<Widget>[
            AiResultView(
              display: display,
              bookId: message.bookId,
              baseCurrencyCode: message.baseCurrencyCode,
              moneyCodeDisplay: message.moneyCodeDisplay,
            ),
            const SizedBox(height: 10),
          ],
          if (message.text.trim().isNotEmpty)
            GptMarkdown(
              message.text,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
              // Markdown 来自模型输出，不能让它凭一个远程 URL 触发网络请求，
              // 从而在用户不知情时暴露 IP、阅读时间或账目上下文。
              imageBuilder: (context, _, _, _) => const _BlockedMarkdownImage(),
            ),
          if (message.provenance case final AiAnswerProvenance provenance)
            _AnswerProvenanceLine(
              provenance: provenance,
              successfulToolCalls: message.successfulToolCalls,
            ),
          if (message.errorText != null) ...<Widget>[
            const SizedBox(height: 8),
            _ErrorBubble(text: message.errorText!, onRetry: onRetry),
          ],
        ],
      ),
    );
  }
}

class _AnswerProvenanceLine extends StatelessWidget {
  const _AnswerProvenanceLine({
    required this.provenance,
    required this.successfulToolCalls,
  });

  final AiAnswerProvenance provenance;
  final int successfulToolCalls;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, text, color) = switch (provenance) {
      AiAnswerProvenance.ledgerQueried => (
        Icons.verified_outlined,
        l10n.aiAnswerProvenanceQueried(successfulToolCalls),
        theme.colorScheme.onSurfaceVariant,
      ),
      AiAnswerProvenance.noLedgerQuery => (
        Icons.info_outline,
        l10n.aiAnswerProvenanceNoQuery,
        theme.colorScheme.onSurfaceVariant,
      ),
      AiAnswerProvenance.noLedgerQueryWithNumericContent => (
        Icons.warning_amber_outlined,
        l10n.aiAnswerProvenanceUnverified,
        veriSemantic(context, veriWarning),
      ),
    };
    return Padding(
      key: const Key('ai_answer_provenance'),
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedMarkdownImage extends StatelessWidget {
  const _BlockedMarkdownImage();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(veriRadiusSm),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.image_not_supported_outlined, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                AppLocalizations.of(context).aiImageBlocked,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 助手出错时的提示气泡（红边淡底，比裸红字更精致）。
class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(veriRadiusMd),
        border: Border.all(color: error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text,
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onErrorContainer,
                      padding: const EdgeInsets.only(top: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(AppLocalizations.of(context).aiRetryAnswer),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
