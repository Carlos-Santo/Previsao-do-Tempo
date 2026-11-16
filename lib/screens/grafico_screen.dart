import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../utils/condicoes_tempo.dart';
import '../utils/formatadores.dart';
import '../widgets/comuns.dart';
import '../widgets/grafico_temperaturas.dart';

/// Gráficos detalhados de temperatura e tabela com os valores.
class GraficoScreen extends StatelessWidget {
  const GraficoScreen({super.key, required this.cidade, required this.previsao});

  final Cidade cidade;
  final PrevisaoCidade previsao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final dias = previsao.dias;
    final maximas = dias.map((d) => d.maxima).whereType<int>();
    final minimas = dias.map((d) => d.minima).whereType<int>();

    return Scaffold(
      appBar: AppBar(title: Text('Gráficos · ${cidade.nome}')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _Resumo(
                  rotulo: 'Maior máxima',
                  valor: maximas.isEmpty ? null : maximas.reduce(math.max),
                ),
                const SizedBox(width: 8),
                _Resumo(
                  rotulo: 'Menor mínima',
                  valor: minimas.isEmpty ? null : minimas.reduce(math.min),
                ),
              ],
            ),
          ),
          _CardGrafico(
            titulo: 'Temperaturas mínima e máxima',
            subtitulo: 'Toque nos pontos para ver os valores',
            legenda: const LegendaTemperaturas(),
            child: GraficoTemperaturas(dias: dias, altura: 260),
          ),
          _CardGrafico(
            titulo: 'Amplitude térmica',
            subtitulo: 'Diferença entre a máxima e a mínima de cada dia',
            child: GraficoAmplitude(dias: dias),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valores', style: tema.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.4),
                      1: FlexColumnWidth(2.2),
                      2: FlexColumnWidth(),
                      3: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _linha(context, ['Dia', 'Condição', 'Mín', 'Máx'],
                          cabecalho: true),
                      for (final d in dias)
                        _linha(context, [
                          d.data == null ? '--' : formatarDiaMes(d.data!),
                          condicaoPorSigla(d.siglaTempo).descricao,
                          formatarTemperatura(d.minima),
                          formatarTemperatura(d.maxima),
                        ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const FonteDados(),
        ],
      ),
    );
  }

  TableRow _linha(BuildContext context, List<String> celulas,
      {bool cabecalho = false}) {
    final tema = Theme.of(context);
    final estilo = cabecalho
        ? tema.textTheme.labelMedium
            ?.copyWith(color: tema.colorScheme.onSurfaceVariant)
        : tema.textTheme.bodyMedium;
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: tema.colorScheme.outlineVariant)),
      ),
      children: [
        for (var i = 0; i < celulas.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              celulas[i],
              style: estilo,
              textAlign: i >= 2 ? TextAlign.end : TextAlign.start,
            ),
          ),
      ],
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.rotulo, required this.valor});

  final String rotulo;
  final int? valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo,
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(formatarTemperatura(valor),
                  style: tema.textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardGrafico extends StatelessWidget {
  const _CardGrafico({
    required this.titulo,
    required this.subtitulo,
    required this.child,
    this.legenda,
  });

  final String titulo;
  final String subtitulo;
  final Widget child;
  final Widget? legenda;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: tema.textTheme.titleMedium),
                  Text(subtitulo,
                      style: tema.textTheme.bodySmall
                          ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
                  if (legenda != null) ...[
                    const SizedBox(height: 8),
                    legenda!,
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
