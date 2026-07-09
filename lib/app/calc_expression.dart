/// 记账数字面板的算式求值：支持 `+ - × ÷` 四则运算、小数与首位负号，无括号，
/// 按标准优先级（先乘除后加减）。纯函数、无 Flutter 依赖，便于单测。
///
/// 返回 `null` 表示算式不完整或无效——末尾挂着运算符、运算符相邻、除以零、
/// 无法解析等，调用方据此提示「算式不完整」并禁用确认。
library;

/// 数字面板使用的运算符显示字符（乘除用 `×`/`÷`，减号用 ASCII `-`）。
const String _multiply = '×';
const String _divide = '÷';

/// 求值 [input]（面板原始输入串，可能含 `×`/`÷`）。不完整或无效时返回 `null`。
double? evaluateAmountExpression(String input) {
  if (input.isEmpty) {
    return null;
  }
  final normalized = input.replaceAll(_multiply, '*').replaceAll(_divide, '/');

  // 分词：把连续数字/小数点归为操作数，`+ - * /` 为运算符；首位 `-`/`+` 视为符号。
  final tokens = <String>[];
  final buffer = StringBuffer();
  for (var i = 0; i < normalized.length; i++) {
    final ch = normalized[i];
    if (ch == '+' || ch == '-' || ch == '*' || ch == '/') {
      if (buffer.isEmpty && i == 0) {
        buffer.write(ch); // 首位符号，并入第一个操作数
        continue;
      }
      tokens
        ..add(buffer.toString())
        ..add(ch);
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  tokens.add(buffer.toString());

  // 拆成操作数与运算符两列，任一操作数不合法即算式不完整。
  final numbers = <double>[];
  final operators = <String>[];
  for (var i = 0; i < tokens.length; i++) {
    if (i.isEven) {
      final token = tokens[i];
      if (token.isEmpty || token == '-' || token == '+' || token == '.') {
        return null;
      }
      final value = double.tryParse(token);
      if (value == null) {
        return null;
      }
      numbers.add(value);
    } else {
      operators.add(tokens[i]);
    }
  }
  if (numbers.length != operators.length + 1) {
    return null;
  }

  // 先做乘除，折叠进操作数序列。
  final foldedNumbers = <double>[numbers.first];
  final foldedOperators = <String>[];
  for (var i = 0; i < operators.length; i++) {
    final op = operators[i];
    final rhs = numbers[i + 1];
    if (op == '*') {
      foldedNumbers[foldedNumbers.length - 1] = foldedNumbers.last * rhs;
    } else if (op == '/') {
      if (rhs == 0) {
        return null; // 除以零：视为无效算式
      }
      foldedNumbers[foldedNumbers.length - 1] = foldedNumbers.last / rhs;
    } else {
      foldedOperators.add(op);
      foldedNumbers.add(rhs);
    }
  }

  // 再做加减。
  var result = foldedNumbers.first;
  for (var i = 0; i < foldedOperators.length; i++) {
    result += foldedOperators[i] == '+'
        ? foldedNumbers[i + 1]
        : -foldedNumbers[i + 1];
  }
  // 金额是钱，把结果规整到「分」，消除浮点尾差
  // （如 0.1+0.2 得 0.30 而非 0.30000000000000004 存进库）。
  return (result * 100).roundToDouble() / 100;
}

/// [input] 去掉首位负号后是否仍含运算符——含则为「算式」，面板据此展示结果预览。
bool amountExpressionHasOperator(String input) {
  final body = input.startsWith('-') ? input.substring(1) : input;
  return body.contains('+') ||
      body.contains('-') ||
      body.contains(_multiply) ||
      body.contains(_divide);
}
