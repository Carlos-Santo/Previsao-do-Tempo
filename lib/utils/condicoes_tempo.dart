import 'package:flutter/material.dart';

/// Descrição, ícone e cor de uma condição do tempo.
class CondicaoTempo {
  const CondicaoTempo(this.descricao, this.icone, this.cor);

  final String descricao;
  final IconData icone;
  final Color cor;
}

const _sol = Color(0xFFF2A007);
const _nuvem = Color(0xFF78909C);
const _chuva = Color(0xFF1E88E5);
const _tempestade = Color(0xFF5E35B1);
const _frio = Color(0xFF4FC3F7);

/// Siglas de condição do tempo conforme a documentação do CPTEC/INPE
/// (http://servicos.cptec.inpe.br/XML/#condicoes-tempo).
const Map<String, CondicaoTempo> condicoesTempo = {
  'ec': CondicaoTempo('Encoberto com chuvas isoladas', Icons.grain, _chuva),
  'ci': CondicaoTempo('Chuvas isoladas', Icons.grain, _chuva),
  'c': CondicaoTempo('Chuva', Icons.umbrella, _chuva),
  'in': CondicaoTempo('Instável', Icons.thunderstorm, _tempestade),
  'pp': CondicaoTempo(
      'Possibilidade de pancadas de chuva', Icons.water_drop, _chuva),
  'cm': CondicaoTempo('Chuva pela manhã', Icons.umbrella, _chuva),
  'cn': CondicaoTempo('Chuva à noite', Icons.umbrella, _chuva),
  'pt': CondicaoTempo('Pancadas de chuva à tarde', Icons.water_drop, _chuva),
  'pm': CondicaoTempo(
      'Pancadas de chuva pela manhã', Icons.water_drop, _chuva),
  'np': CondicaoTempo('Nublado e pancadas de chuva', Icons.grain, _chuva),
  'pc': CondicaoTempo('Pancadas de chuva', Icons.water_drop, _chuva),
  'pn': CondicaoTempo('Parcialmente nublado', Icons.wb_cloudy, _nuvem),
  'cv': CondicaoTempo('Chuvisco', Icons.grain, _chuva),
  'ch': CondicaoTempo('Chuvoso', Icons.umbrella, _chuva),
  't': CondicaoTempo('Tempestade', Icons.thunderstorm, _tempestade),
  'ps': CondicaoTempo('Predomínio de sol', Icons.wb_sunny, _sol),
  'e': CondicaoTempo('Encoberto', Icons.cloud, _nuvem),
  'n': CondicaoTempo('Nublado', Icons.cloud, _nuvem),
  'cl': CondicaoTempo('Céu claro', Icons.wb_sunny, _sol),
  'nv': CondicaoTempo('Nevoeiro', Icons.foggy, _nuvem),
  'g': CondicaoTempo('Geada', Icons.ac_unit, _frio),
  'ne': CondicaoTempo('Neve', Icons.cloudy_snowing, _frio),
  'nd': CondicaoTempo('Não definido', Icons.help_outline, _nuvem),
  'pnt': CondicaoTempo('Pancadas de chuva à noite', Icons.water_drop, _chuva),
  'psc': CondicaoTempo('Possibilidade de chuva', Icons.umbrella, _chuva),
  'pcm': CondicaoTempo(
      'Possibilidade de chuva pela manhã', Icons.umbrella, _chuva),
  'pct':
      CondicaoTempo('Possibilidade de chuva à tarde', Icons.umbrella, _chuva),
  'pcn':
      CondicaoTempo('Possibilidade de chuva à noite', Icons.umbrella, _chuva),
  'npt': CondicaoTempo('Nublado com pancadas à tarde', Icons.grain, _chuva),
  'npn': CondicaoTempo('Nublado com pancadas à noite', Icons.grain, _chuva),
  'ncn': CondicaoTempo(
      'Nublado com possibilidade de chuva à noite', Icons.grain, _chuva),
  'nct': CondicaoTempo(
      'Nublado com possibilidade de chuva à tarde', Icons.grain, _chuva),
  'ncm': CondicaoTempo(
      'Nublado com possibilidade de chuva pela manhã', Icons.grain, _chuva),
  'npm': CondicaoTempo('Nublado com pancadas pela manhã', Icons.grain, _chuva),
  'npp': CondicaoTempo(
      'Nublado com possibilidade de chuva', Icons.grain, _chuva),
  'vn': CondicaoTempo('Variação de nebulosidade', Icons.filter_drama, _nuvem),
  'ct': CondicaoTempo('Chuva à tarde', Icons.umbrella, _chuva),
  'ppn': CondicaoTempo(
      'Possibilidade de pancadas de chuva à noite', Icons.water_drop, _chuva),
  'ppt': CondicaoTempo(
      'Possibilidade de pancadas de chuva à tarde', Icons.water_drop, _chuva),
  'ppm': CondicaoTempo(
      'Possibilidade de pancadas de chuva pela manhã', Icons.water_drop, _chuva),
};

const _desconhecida =
    CondicaoTempo('Condição não informada', Icons.help_outline, _nuvem);

/// Converte a sigla do CPTEC em uma descrição compreensível.
/// Siglas ausentes ou desconhecidas não derrubam o aplicativo.
CondicaoTempo condicaoPorSigla(String? sigla) {
  if (sigla == null) return _desconhecida;
  return condicoesTempo[sigla.trim().toLowerCase()] ??
      CondicaoTempo('Condição "$sigla"', Icons.help_outline, _nuvem);
}

/// Classificação do índice ultravioleta (escala da OMS).
class CategoriaUv {
  const CategoriaUv(this.nome, this.cor);

  final String nome;
  final Color cor;
}

CategoriaUv categoriaUv(double iuv) {
  if (iuv < 3) return const CategoriaUv('Baixo', Color(0xFF43A047));
  if (iuv < 6) return const CategoriaUv('Moderado', Color(0xFFF9A825));
  if (iuv < 8) return const CategoriaUv('Alto', Color(0xFFEF6C00));
  if (iuv < 11) return const CategoriaUv('Muito alto', Color(0xFFD32F2F));
  return const CategoriaUv('Extremo', Color(0xFF7B1FA2));
}
