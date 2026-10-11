part of 'common_widgets.dart';

// 月历热力图：12 个月各一张迷你日历，每天一个方块，颜色按数值深浅。
//
// 为什么是 Widget 而不是自绘图表：仓库约定「数据图表一律走 `chart_painters.dart`
// 适配层、不新增自绘数据图表」，而 `fl_chart` 没有热力图；月历网格属于布局范畴，
// 与 `CalendarPreview` 同一类做法。
//
// 几何与性能取舍（格子每年最多 366 个）：
// - 格子**固定边长**，由可用宽度一次算出，不用 `AspectRatio` 逐格求解；
// - 用「一周一行、一行恰好 7 格」的显式行布局，不用 `Wrap`：当格子总宽刚好等于
//   可用宽度时，浮点误差会让第 7 格被换到下一行，导致每月少一列、右侧多出一块
//   空白，月份之间也显得更散；
// - 整盘按算出的实际宽度居中，左右留白天然对称；
// - 领空格只占位、不生成装饰 Widget；外层包 `RepaintBoundary`，滚动或祖先重建不重绘。
class VeriCalendarHeatmap extends StatelessWidget {
  const VeriCalendarHeatmap({
    super.key,
    required this.year,
    required this.dailyValues,
    required this.color,
    required this.emptyColor,
    required this.monthLabelOf,
    this.columns = 4,
    this.labelSpacing = 6,
    this.cellSpacing = 2,
    this.monthSpacingInCells = 1.8,
  }) : assert(columns > 0);

  final int year;

  /// 从 1 月 1 日起按天排列的数值；不足一年的部分按 0 处理。
  final List<double> dailyValues;

  /// 有记录时的深浅基准色。
  final Color color;

  /// 无记录（值为 0）时的底色。
  final Color emptyColor;

  /// 月份标题（如「1月」），由调用方提供本地化文案。
  final String Function(int month) monthLabelOf;

  /// 每行放几个月。
  final int columns;

  /// 月份标题与网格之间的间距。
  final double labelSpacing;

  /// 相邻两个格子之间的间距。
  final double cellSpacing;

  /// 月份之间的间距，单位是「一个格子的步长（边长 + 格间距）」。
  final double monthSpacingInCells;

  @override
  Widget build(BuildContext context) {
    final peak = dailyValues.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 设格子步长为 t（= 边长 + 格间距）、月份间距为 m·t，则整盘宽度
          //   W = columns·7t + (columns-1)·m·t = (7·columns + (columns-1)·m)·t
          // 反解 t 即可；整盘再居中，左右留白天然相等。
          // 一个月占 7 个步长（含最后一格右侧的间距），格宽一致才不会溢出。
          const cellsPerMonth = 7.0;
          final m = monthSpacingInCells;
          final divisor = cellsPerMonth * columns + (columns - 1) * m;
          final slotWidth = constraints.maxWidth / divisor;
          final cellSize = (slotWidth - cellSpacing).clamp(4.0, 9.5);
          final step = cellSize + cellSpacing;
          final monthWidth = cellsPerMonth * step;
          final gridWidth = columns * monthWidth + (columns - 1) * m * step;

          final months = <Widget>[
            for (var month = 1; month <= 12; month++)
              _VeriHeatMonth(
                year: year,
                month: month,
                dailyValues: dailyValues,
                peak: peak,
                color: color,
                emptyColor: emptyColor,
                label: monthLabelOf(month),
                cellSize: cellSize,
                cellSpacing: cellSpacing,
                step: step,
                monthWidth: monthWidth,
                labelSpacing: labelSpacing,
              ),
          ];

          return Center(
            child: SizedBox(
              width: gridWidth,
              child: Column(
                children: <Widget>[
                  for (var row = 0; row * columns < months.length; row++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: row * columns + columns < months.length
                            ? m * step
                            : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (var column = 0; column < columns; column++)
                            Padding(
                              padding: EdgeInsets.only(
                                right: column == columns - 1 ? 0 : m * step,
                              ),
                              child: SizedBox(
                                width: monthWidth,
                                child: row * columns + column < months.length
                                    ? months[row * columns + column]
                                    : const SizedBox.shrink(),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 单个月份的迷你日历：按星期对齐，一周一行、一行恰好 7 格。
class _VeriHeatMonth extends StatelessWidget {
  const _VeriHeatMonth({
    required this.year,
    required this.month,
    required this.dailyValues,
    required this.peak,
    required this.color,
    required this.emptyColor,
    required this.label,
    required this.cellSize,
    required this.cellSpacing,
    required this.step,
    required this.monthWidth,
    required this.labelSpacing,
  });

  final int year;
  final int month;
  final List<double> dailyValues;
  final double peak;
  final Color color;
  final Color emptyColor;
  final String label;
  final double cellSize;
  final double cellSpacing;

  /// 一个格子的步长（边长 + 格间距）。
  final double step;

  /// 一个月占用的宽度（7 个步长）。
  final double monthWidth;
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // 该月 1 号在一年中的第几天（1 月 1 日 = 0），用于取每天的数值。
    final offset = firstDay.difference(DateTime(year, 1, 1)).inDays;
    // 周一为第一列。
    final leading = firstDay.weekday - 1;
    final weeks = ((leading + daysInMonth) / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.78),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: labelSpacing),
        for (var week = 0; week < weeks; week++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var weekday = 0; weekday < 7; weekday++)
                _cellAt(
                  week * 7 + weekday - leading,
                  offset,
                  daysInMonth,
                  step,
                ),
            ],
          ),
      ],
    );
  }

  Widget _cellAt(int dayIndex, int offset, int daysInMonth, double step) {
    if (dayIndex < 0 || dayIndex >= daysInMonth) {
      return SizedBox(width: step, height: step);
    }
    final index = offset + dayIndex;
    final value = index < dailyValues.length ? dailyValues[index] : 0.0;
    final ratio = peak <= 0 ? 0.0 : (value / peak).clamp(0.0, 1.0);
    return Container(
      width: cellSize,
      height: cellSize,
      margin: EdgeInsets.only(right: cellSpacing, bottom: cellSpacing),
      decoration: BoxDecoration(
        // 有记录就从 30% 起步，避免小额和「没有记录」在视觉上分不开。
        color: ratio <= 0
            ? emptyColor
            : color.withValues(alpha: 0.30 + 0.70 * ratio),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
