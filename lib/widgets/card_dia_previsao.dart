import 'package:flutter/material.dart';

import '../models/previsao.dart';
import '../utils/condicoes_tempo.dart';
import '../utils/formatadores.dart';
import 'cores_grafico.dart';

/// Cartão com a previsão de um dia: data, ícone, condição,
/// mínima/máxima e índice UV.
class CardDiaPrevisao extends StatelessWidget {
  const CardDiaPrevisao({super.key, required this.dia, this.hoje});

  final PrevisaoDia dia;

  /// Data de referência para "Hoje"/"Amanhã" (útil em testes).
  final DateTime? hoje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final condicao = condicaoPorSigla(dia.siglaTempo);
    final cores = CoresGrafico.de(context);
    final data = dia.data;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: condicao.cor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(condicao.icone, color: condicao.cor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data == null ? 'Data não informada' : rotuloDia(data, hoje: hoje),
                    style: tema.textTheme.titleMedium,
                  ),
                  if (data != null)
                    Text(
                      formatarData(data),
                      style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 6),
                  Text(condicao.descricao, style: tema.textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Temperatura(
                        icone: Icons.arrow_downward,
                        rotulo: 'Mín',
                        valor: dia.minima,
                        cor: cores.minima,
                      ),
                      _Temperatura(
                        icone: Icons.arrow_upward,
                        rotulo: 'Máx',
                        valor: dia.maxima,
                        cor: cores.maxima,
                      ),
                      _IndiceUv(iuv: dia.iuv),
                    ],
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

class _Temperatura extends StatelessWidget {
  const _Temperatura({
    required this.icone,
    required this.rotulo,
    required this.valor,
    required this.cor,
  });

  final IconData icone;
  final String rotulo;
  final int? valor;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: cor),
        const SizedBox(width: 2),
        Text('$rotulo ', style: tema.textTheme.bodySmall),
        Text(formatarTemperatura(valor),
            style: tema.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _IndiceUv extends StatelessWidget {
  const _IndiceUv({required this.iuv});

  final double? iuv;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final valor = iuv;
    if (valor == null) {
      return Text(
        'UV não disponível',
        style: tema.textTheme.bodySmall
            ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
      );
    }
    final categoria = categoriaUv(valor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wb_sunny_outlined, size: 16, color: categoria.cor),
        const SizedBox(width: 4),
        Text(
          'UV ${valor.toStringAsFixed(valor % 1 == 0 ? 0 : 1)} · ${categoria.nome}',
          style: tema.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
