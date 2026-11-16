import 'package:flutter/material.dart';

/// Mensagem centralizada para estados vazios e de erro.
class EstadoMensagem extends StatelessWidget {
  const EstadoMensagem({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.aoAgir,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? rotuloAcao;
  final VoidCallback? aoAgir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: tema.colorScheme.outline),
            const SizedBox(height: 16),
            Text(titulo,
                style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              mensagem,
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (rotuloAcao != null && aoAgir != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: aoAgir,
                icon: const Icon(Icons.refresh),
                label: Text(rotuloAcao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Identificação da fonte dos dados, exigida em todas as telas.
class FonteDados extends StatelessWidget {
  const FonteDados({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.satellite_alt,
              size: 16, color: tema.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Fonte dos dados: CPTEC/INPE',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
