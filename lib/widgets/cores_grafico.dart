import 'package:flutter/material.dart';

/// Cores das séries dos gráficos, com variações próprias para o tema escuro.
/// Par azul/laranja validado para daltonismo e contraste nos dois temas.
class CoresGrafico {
  const CoresGrafico._(this.maxima, this.minima, this.amplitude);

  final Color maxima;
  final Color minima;
  final Color amplitude;

  static CoresGrafico de(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const CoresGrafico._(
              Color(0xFFD95926), Color(0xFF3987E5), Color(0xFF9085E9))
          : const CoresGrafico._(
              Color(0xFFEB6834), Color(0xFF2A78D6), Color(0xFF6250D6));
}
