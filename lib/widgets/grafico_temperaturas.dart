import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/previsao.dart';
import '../utils/formatadores.dart';
import 'cores_grafico.dart';

/// Gráfico de linhas com as temperaturas mínima e máxima de cada dia.
class GraficoTemperaturas extends StatelessWidget {
  const GraficoTemperaturas({super.key, required this.dias, this.altura = 220});

  final List<PrevisaoDia> dias;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresGrafico.de(context);
    final temperaturas = [
      for (final d in dias) ...[if (d.maxima != null) d.maxima!, if (d.minima != null) d.minima!],
    ];

    if (temperaturas.isEmpty) {
      return SizedBox(
        height: altura / 2,
        child: Center(
          child: Text('Sem temperaturas para exibir no gráfico.',
              style: tema.textTheme.bodyMedium),
        ),
      );
    }

    final menor = temperaturas.reduce(math.min);
    final maior = temperaturas.reduce(math.max);
    // Margem de 3 °C e limites múltiplos de 5 para o eixo ficar legível.
    final minY = ((menor - 3) / 5).floor() * 5.0;
    final maxY = ((maior + 3) / 5).ceil() * 5.0;
    final textoEixo = tema.textTheme.bodySmall
        ?.copyWith(color: tema.colorScheme.onSurfaceVariant);
    final corGrade = tema.colorScheme.outlineVariant.withValues(alpha: 0.6);

    LineChartBarData serie(int? Function(PrevisaoDia) valor, Color cor) =>
        LineChartBarData(
          spots: [
            for (var i = 0; i < dias.length; i++)
              valor(dias[i]) == null
                  ? FlSpot.nullSpot
                  : FlSpot(i.toDouble(), valor(dias[i])!.toDouble()),
          ],
          color: cor,
          barWidth: 2,
          isCurved: true,
          preventCurveOverShooting: true,
          dotData: FlDotData(
            getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
              radius: 5,
              color: cor,
              strokeWidth: 2,
              strokeColor: tema.colorScheme.surface,
            ),
          ),
        );

    return Semantics(
      label: 'Gráfico de temperaturas mínimas e máximas. '
          '${_descricaoAcessivel()}',
      child: SizedBox(
        height: altura,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 8),
          child: LineChart(
            LineChartData(
              minX: -0.25,
              maxX: dias.length - 0.75,
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                serie((d) => d.maxima, cores.maxima),
                serie((d) => d.minima, cores.minima),
              ],
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: corGrade, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    reservedSize: 40,
                    getTitlesWidget: (valor, meta) {
                      if (valor % 5 != 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text('${valor.toInt()}°', style: textoEixo),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 40,
                    getTitlesWidget: (valor, meta) {
                      final i = valor.round();
                      if (valor != i || i < 0 || i >= dias.length) {
                        return const SizedBox.shrink();
                      }
                      final data = dias[i].data;
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          data == null
                              ? 'Dia ${i + 1}'
                              : '${diaSemanaCurto(data)}\n${formatarDiaMes(data)}',
                          textAlign: TextAlign.center,
                          style: textoEixo,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => tema.colorScheme.inverseSurface,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (pontos) => [
                    for (final p in pontos)
                      LineTooltipItem(
                        '${p.barIndex == 0 ? 'Máx' : 'Mín'}: ${p.y.toInt()} °C',
                        TextStyle(
                          color: tema.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _descricaoAcessivel() => dias.map((d) {
        final dia = d.data == null ? 'Dia' : formatarDiaMes(d.data!);
        return '$dia: mínima ${formatarTemperatura(d.minima)}, '
            'máxima ${formatarTemperatura(d.maxima)}';
      }).join('; ');
}

/// Gráfico de barras com a amplitude térmica (máxima − mínima) de cada dia.
class GraficoAmplitude extends StatelessWidget {
  const GraficoAmplitude({super.key, required this.dias, this.altura = 180});

  final List<PrevisaoDia> dias;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor = CoresGrafico.de(context).amplitude;
    final amplitudes = [
      for (final d in dias)
        d.maxima != null && d.minima != null ? d.maxima! - d.minima! : null,
    ];
    final validas = amplitudes.whereType<int>();
    if (validas.isEmpty) {
      return SizedBox(
        height: altura / 2,
        child: Center(
          child: Text('Sem dados de amplitude.',
              style: tema.textTheme.bodyMedium),
        ),
      );
    }
    final maxY = ((validas.reduce(math.max) + 3) / 5).ceil() * 5.0;
    final textoEixo = tema.textTheme.bodySmall
        ?.copyWith(color: tema.colorScheme.onSurfaceVariant);

    return SizedBox(
      height: altura,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (_) => FlLine(
                color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
                strokeWidth: 1,
              ),
            ),
            barGroups: [
              for (var i = 0; i < dias.length; i++)
                BarChartGroupData(
                  x: i,
                  showingTooltipIndicators: amplitudes[i] == null ? [] : [0],
                  barRods: [
                    BarChartRodData(
                      toY: (amplitudes[i] ?? 0).toDouble(),
                      color: cor,
                      width: 28,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
            ],
            barTouchData: BarTouchData(
              enabled: false,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                getTooltipItem: (grupo, _, haste, _) => BarTooltipItem(
                  '${haste.toY.toInt()} °C',
                  tema.textTheme.labelMedium!
                      .copyWith(color: tema.colorScheme.onSurface),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  reservedSize: 40,
                  getTitlesWidget: (valor, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text('${valor.toInt()}°', style: textoEixo),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (valor, meta) {
                    final i = valor.toInt();
                    final data = i < dias.length ? dias[i].data : null;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        data == null ? 'Dia ${i + 1}' : formatarDiaMes(data),
                        style: textoEixo,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legenda das séries do gráfico de temperaturas.
class LegendaTemperaturas extends StatelessWidget {
  const LegendaTemperaturas({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = CoresGrafico.de(context);
    Widget item(String rotulo, Color cor) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 4,
              decoration: BoxDecoration(
                  color: cor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
            Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
    return Wrap(
      spacing: 16,
      children: [
        item('Máxima', cores.maxima),
        item('Mínima', cores.minima),
      ],
    );
  }
}
