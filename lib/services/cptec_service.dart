import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/cidade.dart';
import '../models/previsao.dart';
import 'cptec_exception.dart';
import 'cptec_parser.dart';

/// Cliente dos serviços XML do CPTEC/INPE.
///
/// Documentação: http://servicos.cptec.inpe.br/XML/
class CptecService {
  CptecService({http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  static const host = 'servicos.cptec.inpe.br';

  final http.Client _client;
  final Duration timeout;

  /// Consulta as localidades cujo nome começa com [nome].
  Future<List<Cidade>> buscarCidades(String nome) async {
    final uri = Uri.https(host, '/XML/listaCidades', {'city': nome.trim()});
    return CptecParser.cidades(await _get(uri));
  }

  /// Previsão para quatro dias da localidade com o código [idCidade],
  /// que é o identificador devolvido por [buscarCidades].
  Future<PrevisaoCidade> buscarPrevisao(String idCidade) async {
    final uri = Uri.https(
        host, '/XML/cidade/${Uri.encodeComponent(idCidade)}/previsao.xml');
    return CptecParser.previsao(await _get(uri));
  }

  Future<String> _get(Uri uri) async {
    final http.Response resposta;
    try {
      resposta = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const CptecException(
        TipoFalha.semConexao,
        'O CPTEC/INPE demorou demais para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const CptecException(
        TipoFalha.semConexao,
        'Não foi possível conectar. Verifique sua conexão com a internet.',
      );
    } catch (_) {
      throw const CptecException(
        TipoFalha.semConexao,
        'Não foi possível conectar ao CPTEC/INPE.',
      );
    }

    if (resposta.statusCode == 429) {
      throw const CptecException(
        TipoFalha.servicoIndisponivel,
        'Muitas consultas em pouco tempo. Aguarde um instante e tente de novo.',
      );
    }
    if (resposta.statusCode != 200) {
      throw CptecException(
        TipoFalha.servicoIndisponivel,
        'O serviço do CPTEC/INPE está indisponível no momento '
        '(código ${resposta.statusCode}).',
      );
    }
    if (resposta.bodyBytes.isEmpty) {
      throw const CptecException(
        TipoFalha.respostaInvalida,
        'O CPTEC/INPE respondeu sem conteúdo.',
      );
    }
    return CptecParser.decodificar(
      resposta.bodyBytes,
      contentType: resposta.headers['content-type'],
    );
  }

  void fechar() => _client.close();
}
