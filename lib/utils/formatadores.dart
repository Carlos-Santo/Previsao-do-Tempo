const _diasSemana = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

/// 17/11/2026
String formatarData(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';

/// 17/11
String formatarDiaMes(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';

/// 17/11/2026 às 14:05
String formatarDataHora(DateTime data) =>
    '${formatarData(data)} às ${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

String diaSemana(DateTime data) => _diasSemana[data.weekday - 1];

/// "Seg", "Ter"... para eixos de gráfico.
String diaSemanaCurto(DateTime data) => diaSemana(data).substring(0, 3);

/// "Hoje", "Amanhã" ou o dia da semana, em relação a [hoje].
String rotuloDia(DateTime data, {DateTime? hoje}) {
  final ref = hoje ?? DateTime.now();
  final diferenca = DateTime(data.year, data.month, data.day)
      .difference(DateTime(ref.year, ref.month, ref.day))
      .inDays;
  if (diferenca == 0) return 'Hoje';
  if (diferenca == 1) return 'Amanhã';
  return diaSemana(data);
}

String formatarTemperatura(int? graus) => graus == null ? '--' : '$graus °C';
