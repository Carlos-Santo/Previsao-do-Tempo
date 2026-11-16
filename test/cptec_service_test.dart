import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_do_tempo/services/cptec_exception.dart';
import 'package:previsao_do_tempo/services/cptec_service.dart';

import 'fixtures.dart';

Matcher _falha(TipoFalha tipo) =>
    throwsA(isA<CptecException>().having((e) => e.tipo, 'tipo', tipo));

void main() {
  test('pesquisa usa o parâmetro city e decodifica Latin-1', () async {
    final urls = <Uri>[];
    final servico = CptecService(client: clienteFalso(requisicoes: urls));

    final cidades = await servico.buscarCidades('  são paulo ');

    expect(urls.single.host, 'servicos.cptec.inpe.br');
    expect(urls.single.path, '/XML/listaCidades');
    expect(urls.single.queryParameters['city'], 'são paulo');
    expect(cidades.map((c) => c.nome), contains('São Paulo das Missões'));
  });

  test('previsão usa o código retornado pelo serviço', () async {
    final urls = <Uri>[];
    final servico = CptecService(client: clienteFalso(requisicoes: urls));

    final previsao = await servico.buscarPrevisao('244');

    expect(urls.single.path, '/XML/cidade/244/previsao.xml');
    expect(previsao.dias, hasLength(4));
  });

  test('erro HTTP vira servicoIndisponivel', () {
    final servico = CptecService(
        client: MockClient((_) async => http.Response('erro', 503)));
    expect(servico.buscarPrevisao('244'), _falha(TipoFalha.servicoIndisponivel));
  });

  test('limite de requisições (429) tem mensagem própria', () async {
    final servico = CptecService(
        client: MockClient((_) async => http.Response('', 429)));
    await expectLater(
      servico.buscarCidades('rio'),
      throwsA(isA<CptecException>()
          .having((e) => e.mensagem, 'mensagem', contains('Muitas consultas'))),
    );
  });

  test('falha de rede vira semConexao', () {
    final servico = CptecService(
        client: MockClient((_) async => throw http.ClientException('offline')));
    expect(servico.buscarCidades('rio'), _falha(TipoFalha.semConexao));
  });

  test('tempo esgotado vira semConexao', () {
    final servico = CptecService(
      client: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    );
    expect(servico.buscarCidades('rio'), _falha(TipoFalha.semConexao));
  });

  test('corpo vazio ou que não é XML vira respostaInvalida', () {
    final vazio =
        CptecService(client: MockClient((_) async => http.Response('', 200)));
    final html = CptecService(
        client: MockClient((_) async => http.Response('<html>oops', 200)));
    expect(vazio.buscarCidades('rio'), _falha(TipoFalha.respostaInvalida));
    expect(html.buscarPrevisao('1'), _falha(TipoFalha.respostaInvalida));
  });
}
