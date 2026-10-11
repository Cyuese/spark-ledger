part of 'common_widgets.dart';

// 月历热力图：12 个月各一张迷你日历，每天一个方块，颜色按数值深浅。
//
// 为什么是 Widget 而不是自绘图表：仓库约定「数据图表一律走 `chart_painters.dart`
// 适配层、不新增自绘数据图表」，而 `fl_chart` 没有热力图；月历网格属于布局范畴，
// 与 `CalendarPreview` 同一类做法。
//
// 性能取舍（格子数量可达每年 366 个）：
// - 用**固定尺寸**格子（`cellSize` 由可用宽度一次算出），不用 `AspectRatio`
//   逐格做比例求解，避免每个格子一次额外布局；
// - 领空格（月初之前的空位）不生成 Widget，只用一段固定宽度的占位；
// - 整块网格包一层 `RepaintBoundary`，页面滚动或祖先重建时不重绘；
// - 颜色只算一次 alpha，避免每格重复 `clamp`/除法以外的开销。
class VeriCalendarHeatmap extends StatelessWidget {
  const VeriCalendarHeatmap({
    super.key,
    required this.year,
    required this.dailyValues,
    required this.color,
    required this.emptyColor,
    required this.monthLabelOf,
    this.columns = 4,
    this.monthSpacing = 16,
    this.labelSpacing = 6,
  });

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

  /// 月份之间的间距（横向与纵向都用它）。
  final double monthSpacing;

  /// 月份标题与网格之间的间距。
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    final peak = dailyValues.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 格子尺寸按可用宽度反推一次，7 列 + 列间距必须装得下。
          const cellSpacing = 2.0;
          final monthWidth =
              (constraints.maxWidth - (columns - 1) * monthSpacing) / columns;
          final cellSize = ((monthWidth - 6 * cellSpacing) / 7).clamp(5.0, 9.0);
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
                labelSpacing: labelSpacing,
              ),
          ];
          return Column(
            children: <Widget>[
              for (var row = 0; row * columns < months.length; row++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: row * columns + columns < months.length
                        ? monthSpacing
                        : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (var column = 0; column < columns; column++)
                        Padding(
                          padding: EdgeInsets.only(
                            right: column == columns - 1 ? 0 : monthSpacing,
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
          );
        },
      ),
    );
  }
}

/// 单个月份的迷你日历：按星期对齐的 7 列网格，每格一天。
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
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // 该月 1 号在一年中的第几天（1 月 1 日 = 0），用于取每天的数值。
    final offset = DateTime(
      year,
      month,
      1,
    ).difference(DateTime(year, 1, 1)).inDays;
    // 周一为第一列。
    final leading = DateTime(year, month, 1).weekday - 1;
    final step = cellSize + cellSpacing;

    final cells = <Widget>[];
    if (leading > 0) {
      cells.add(SizedBox(width: leading * step));
    }
    for (var day = 0; day < daysInMonth; day++) {
      final index = offset + day;
      final value = index < dailyValues.length ? dailyValues[index] : 0.0;
      final ratio = peak <= 0 ? 0.0 : (value / peak).clamp(0.0, 1.0);
      cells.add(
        Container(
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
        ),
      );
    }

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
        Wrap(spacing: 0, runSpacing: 0, children: cells),
      ],
    );
  }
}
