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
    this.secondaryAxis = false,
  });

  final String label;
  final List<SignalPoint> points;
  final Color color;
  final bool dashed;
  final bool dots;

  /// Quando true, os valores desta série são reais em [ResponseChart.secondaryMin]-
  /// [ResponseChart.secondaryMax] (ex.: MV em 0-100%), plotados no mesmo
  /// espaço visual do eixo esquerdo mas rotulados de forma independente no
  /// eixo direito — permite duas escalas diferentes no mesmo gráfico.
  final bool secondaryAxis;
}

class ResponseChart extends StatelessWidget {
  const ResponseChart({
    super.key,
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.series,
    this.height = 300,
    this.transformationController,
    this.onTouch,
    this.extraVerticalLines = const [],
    this.extraHorizontalLines = const [],
    this.leftMin,
    this.leftMax,
    this.secondaryMin,
    this.secondaryMax,
    this.secondaryAxisLabel,
  });

  final String title;
  final String xLabel;
  final String yLabel;
  final List<ChartSeries> series;
  final double height;

  /// Faixa fixa do eixo esquerdo (PV/SP). Quando omitida, a faixa é
  /// calculada automaticamente a partir dos dados, como antes.
  final double? leftMin;
  final double? leftMax;

  /// Faixa real (não normalizada) das séries com [ChartSeries.secondaryAxis]
  /// — ex.: 0 e 100 para MV em %. Necessário para desenhar o eixo direito.
  final double? secondaryMin;
  final double? secondaryMax;
  final String? secondaryAxisLabel;

  /// Quando definido, habilita pan (arrastar) e zoom (scroll/pinch) livres
  /// no gráfico. Opcional — sem ele o gráfico permanece estático, como
  /// usado nas curvas de simulação/what-if.
  final TransformationController? transformationController;

  /// Callback de toque bruto (posição em pixel e em coordenada de dados),
  /// usado pelas ferramentas de cursor/tangente do gráfico ao vivo.
  final void Function(FlTouchEvent event, LineTouchResponse? response)?
  onTouch;

  /// Linhas verticais/horizontais extras (cursores de medição) desenhadas
  /// por cima das séries.
  final List<VerticalLine> extraVerticalLines;
  final List<HorizontalLine> extraHorizontalLines;

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

    final hasSecondary =
        secondaryMin != null &&
        secondaryMax != null &&
        visible.any((s) => s.secondaryAxis);

    double minY;
    double maxY;
    if (leftMin != null && leftMax != null) {
      minY = leftMin!;
      maxY = leftMax!;
    } else {
      final boundsSource = visible.where((s) => !s.secondaryAxis).toList();
      final boundsPoints = [
        for (final s in boundsSource.isEmpty ? visible : boundsSource)
          ...s.points,
      ];
      minY = boundsPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      maxY = boundsPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b);
      final pad = (maxY - minY).abs() * 0.10 + 1e-6;
      minY -= pad;
      maxY += pad;
    }

    double toPlotY(ChartSeries item, double y) {
      if (!hasSecondary || !item.secondaryAxis) return y;
      return _toPlotSpace(y, secondaryMin!, secondaryMax!, minY, maxY);
    }

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
              transformationConfig: transformationController == null
                  ? const FlTransformationConfig()
                  : FlTransformationConfig(
                      scaleAxis: FlScaleAxis.free,
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 1,
                      maxScale: 20,
                      transformationController: transformationController,
                    ),
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
                  rightTitles: !hasSecondary
                      ? const AxisTitles()
                      : AxisTitles(
                          axisNameSize: 36,
                          axisNameWidget: secondaryAxisLabel == null
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    secondaryAxisLabel!,
                                    style: const TextStyle(
                                      color: AppPalette.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                _fmt(
                                  _fromPlotSpace(
                                    value,
                                    minY,
                                    maxY,
                                    secondaryMin!,
                                    secondaryMax!,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: AppPalette.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
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
                extraLinesData: ExtraLinesData(
                  verticalLines: extraVerticalLines,
                  horizontalLines: extraHorizontalLines,
                ),
                lineTouchData: LineTouchData(
                  touchCallback: onTouch,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppPalette.textPrimary,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final item = visible[spot.barIndex];
                      final realY = hasSecondary && item.secondaryAxis
                          ? _fromPlotSpace(
                              spot.y,
                              minY,
                              maxY,
                              secondaryMin!,
                              secondaryMax!,
                            )
                          : spot.y;
                      return LineTooltipItem(
                        '${spot.x.toStringAsFixed(2)} s\n${realY.toStringAsFixed(3)}',
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
                      spots: item.points
                          .map((p) => FlSpot(p.t, toPlotY(item, p.y)))
                          .toList(),
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

/// Remapeia [value] (na escala real de [realMin]-[realMax]) para o espaço
/// visual compartilhado do gráfico ([plotMin]-[plotMax]) — usado para
/// desenhar uma série de [ChartSeries.secondaryAxis] na mesma área do
/// gráfico das séries do eixo principal, com escala independente.
double _toPlotSpace(
  double value,
  double realMin,
  double realMax,
  double plotMin,
  double plotMax,
) {
  final t = realMax == realMin ? 0.0 : (value - realMin) / (realMax - realMin);
  return plotMin + t * (plotMax - plotMin);
}

/// Inverso de [_toPlotSpace] — usado para rotular o eixo direito e o
/// tooltip com o valor real (não normalizado) das séries do eixo
/// secundário.
double _fromPlotSpace(
  double plotValue,
  double plotMin,
  double plotMax,
  double realMin,
  double realMax,
) {
  final t = plotMax == plotMin ? 0.0 : (plotValue - plotMin) / (plotMax - plotMin);
  return realMin + t * (realMax - realMin);
}
