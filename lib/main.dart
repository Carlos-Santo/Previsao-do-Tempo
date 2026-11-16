import 'package:flutter/material.dart';

import 'screens/busca_screen.dart';
import 'services/armazenamento_local.dart';
import 'services/cptec_service.dart';

void main() {
  runApp(PrevisaoApp(
    servico: CptecService(),
    armazenamento: ArmazenamentoLocal.criar(),
  ));
}

class PrevisaoApp extends StatelessWidget {
  const PrevisaoApp({
    super.key,
    required this.servico,
    required this.armazenamento,
    this.temaForcado,
  });

  final CptecService servico;
  final ArmazenamentoLocal armazenamento;

  /// Permite fixar claro/escuro (usado nas capturas de tela).
  final ThemeMode? temaForcado;

  static ThemeData tema(Brightness brilho) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: brilho,
        ),
        cardTheme: const CardThemeData(elevation: 0),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Previsão do Tempo',
      debugShowCheckedModeBanner: false,
      theme: tema(Brightness.light),
      darkTheme: tema(Brightness.dark),
      themeMode: temaForcado ?? ThemeMode.system,
      home: BuscaScreen(servico: servico, armazenamento: armazenamento),
    );
  }
}
