import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/signal_point.dart';
import '../theme/app_palette.dart';

class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.points,
    required this.color,
    this.dashed = false,
    this.dots = false,
  });

  final String label;
  final List<SignalPoint> points;
  final Color color;
  final bool dashed;
  final bool dots;
}

class ResponseChart extends StatelessWidget {
  const ResponseChart({
    super.key,
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.series,
    this.height = 300,
  });

  final String title;
  final String xLabel;
  final String yLabel;
  final List<ChartSeries> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    final visible = series.where((s) => s.points.isNotEmpty).toList();
    if (visible.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Preencha valores válidos para gerar as curvas.',
            style: TextStyle(color: AppPalette.textSecondary),
          ),
        ),
      );
    }

    final all = [for (final s in visible) ...s.points];
    final minX = all.map((p) => p.t).reduce((a, b) => a < b ? a : b);
    final maxX = all.map((p) => p.t).reduce((a, b) => a > b ? a : b);
    var minY = all.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    var maxY = all.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.10 + 1e-6;
    minY -= pad;
    maxY += pad;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final item in visible)
                      _Legend(
                        label: item.label,
                        color: item.color,
                        dot: item.dots,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX <= minX ? minX + 1 : maxX,
                minY: minY,
                maxY: maxY <= minY ? minY + 1 : maxY,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFEAEEF3), strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: Color(0xFFEAEEF3), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    axisNameSize: 28,
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        xLabel,
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    sideTitles: const SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: _bottomLabel,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameSize: 36,
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        yLabel,
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    sideTitles: const SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: _leftLabel,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Color(0xFFCBD5E1)),
                    bottom: BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppPalette.textPrimary,
                    getTooltipItems: (spots) => spots.map((spot) {
                      return LineTooltipItem(
                        '${spot.x.toStringAsFixed(2)} s\n${spot.y.toStringAsFixed(3)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  for (final item in visible)
                    LineChartBarData(
                      spots: item.points.map((p) => FlSpot(p.t, p.y)).toList(),
                      isCurved: false,
                      color: item.dots ? Colors.transparent : item.color,
                      barWidth: item.dots ? 0 : 2.4,
                      dashArray: item.dashed ? [6, 4] : null,
                      dotData: FlDotData(
                        show: item.dots,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 4.5,
                              color: Colors.white,
                              strokeWidth: 2.2,
                              strokeColor: item.color,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show:
                            !item.dashed &&
                            !item.dots &&
                            item.label == 'PV PID',
                        color: item.color.withValues(alpha: 0.06),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color, required this.dot});

  final String label;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot ? 10 : 18,
          height: dot ? 10 : 3,
          decoration: BoxDecoration(
            color: dot ? Colors.white : color,
            border: dot ? Border.all(color: color, width: 2) : null,
            borderRadius: BorderRadius.circular(dot ? 999 : 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

Widget _leftLabel(double value, TitleMeta meta) {
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Text(
      _fmt(value),
      style: const TextStyle(color: AppPalette.textSecondary, fontSize: 11),
      textAlign: TextAlign.right,
    ),
  );
}

Widget _bottomLabel(double value, TitleMeta meta) {
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      _fmt(value),
      style: const TextStyle(color: AppPalette.textSecondary, fontSize: 11),
    ),
  );
}

String _fmt(double value) {
  final a = value.abs();
  if (a >= 10000) return value.toStringAsExponential(1);
  if (a >= 100) return value.toStringAsFixed(0);
  if (a >= 10) return value.toStringAsFixed(1);
  return value.toStringAsFixed(2);
}
