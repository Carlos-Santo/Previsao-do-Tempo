import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';

/// Persistência local com `shared_preferences` (pares chave/valor),
/// guardando os dados como JSON.
///
/// - `favoritas`: cidades marcadas com estrela;
/// - `historico`: últimas cidades consultadas (mais recente primeiro);
/// - `previsao_<id>`: última previsão recebida de cada cidade, usada
///   quando não há conexão.
class ArmazenamentoLocal {
  ArmazenamentoLocal(this._prefs);

  static const _chaveFavoritas = 'favoritas';
  static const _chaveHistorico = 'historico';
  static const _prefixoPrevisao = 'previsao_';
  static const limiteHistorico = 8;

  final SharedPreferencesAsync _prefs;

  static ArmazenamentoLocal criar() =>
      ArmazenamentoLocal(SharedPreferencesAsync());

  // ---------- Favoritas ----------

  Future<List<Cidade>> favoritas() => _lerCidades(_chaveFavoritas);

  Future<bool> ehFavorita(Cidade cidade) async =>
      (await favoritas()).contains(cidade);

  /// Alterna a cidade nas favoritas e devolve o novo estado.
  Future<bool> alternarFavorita(Cidade cidade) async {
    final lista = await favoritas();
    final passouASerFavorita = !lista.remove(cidade);
    if (passouASerFavorita) lista.add(cidade);
    lista.sort((a, b) => a.nome.compareTo(b.nome));
    await _salvarCidades(_chaveFavoritas, lista);
    return passouASerFavorita;
  }

  // ---------- Histórico ----------

  Future<List<Cidade>> historico() => _lerCidades(_chaveHistorico);

  Future<void> registrarNoHistorico(Cidade cidade) async {
    final lista = await historico()
      ..remove(cidade)
      ..insert(0, cidade);
    await _salvarCidades(
        _chaveHistorico, lista.take(limiteHistorico).toList());
  }

  Future<void> limparHistorico() => _prefs.remove(_chaveHistorico);

  // ---------- Previsões em cache ----------

  Future<void> salvarPrevisao(Cidade cidade, PrevisaoCidade previsao,
      {DateTime? agora}) async {
    await _prefs.setString(
      '$_prefixoPrevisao${cidade.id}',
      jsonEncode({
        'salvaEm': (agora ?? DateTime.now()).toIso8601String(),
        'previsao': previsao.toJson(),
      }),
    );
  }

  Future<PrevisaoSalva?> previsaoSalva(Cidade cidade) async {
    final json = await _lerJson('$_prefixoPrevisao${cidade.id}');
    if (json is! Map) return null;
    final salvaEm = json['salvaEm'];
    final previsao = PrevisaoCidade.fromJson(json['previsao']);
    if (salvaEm is! String || previsao == null) return null;
    final data = DateTime.tryParse(salvaEm);
    if (data == null) return null;
    return PrevisaoSalva(previsao: previsao, salvaEm: data);
  }

  // ---------- Auxiliares ----------

  Future<List<Cidade>> _lerCidades(String chave) async {
    final json = await _lerJson(chave);
    if (json is! List) return [];
    return json.map(Cidade.fromJson).whereType<Cidade>().toList();
  }

  Future<void> _salvarCidades(String chave, List<Cidade> cidades) =>
      _prefs.setString(
          chave, jsonEncode(cidades.map((c) => c.toJson()).toList()));

  /// Dados corrompidos são tratados como ausentes, sem derrubar o app.
  Future<Object?> _lerJson(String chave) async {
    try {
      final texto = await _prefs.getString(chave);
      return texto == null ? null : jsonDecode(texto);
    } catch (_) {
      return null;
    }
  }
}
