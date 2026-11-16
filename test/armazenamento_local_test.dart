import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_do_tempo/models/cidade.dart';
import 'package:previsao_do_tempo/services/armazenamento_local.dart';
import 'package:previsao_do_tempo/services/cptec_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fixtures.dart';

const _sp = Cidade(id: '244', nome: 'São Paulo', uf: 'SP');
const _campinas = Cidade(id: '1', nome: 'Campinas', uf: 'SP');

void main() {
  late ArmazenamentoLocal armazenamento;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    armazenamento = ArmazenamentoLocal(SharedPreferencesAsync());
  });

  test('favoritas: adiciona, ordena por nome e remove', () async {
    expect(await armazenamento.alternarFavorita(_sp), isTrue);
    expect(await armazenamento.alternarFavorita(_campinas), isTrue);
    expect((await armazenamento.favoritas()).map((c) => c.nome),
        ['Campinas', 'São Paulo']);

    expect(await armazenamento.alternarFavorita(_sp), isFalse);
    expect(await armazenamento.ehFavorita(_sp), isFalse);
    expect(await armazenamento.favoritas(), [_campinas]);
  });

  test('histórico: mais recente primeiro, sem repetir, com limite', () async {
    for (var i = 0; i < 12; i++) {
      await armazenamento
          .registrarNoHistorico(Cidade(id: '$i', nome: 'Cidade $i', uf: 'SP'));
    }
    await armazenamento.registrarNoHistorico(
        const Cidade(id: '5', nome: 'Cidade 5', uf: 'SP'));

    final historico = await armazenamento.historico();
    expect(historico, hasLength(ArmazenamentoLocal.limiteHistorico));
    expect(historico.first.id, '5');
    expect(historico.where((c) => c.id == '5'), hasLength(1));

    await armazenamento.limparHistorico();
    expect(await armazenamento.historico(), isEmpty);
  });

  test('previsão salva é recuperada com a data em que foi salva', () async {
    final previsao = CptecParser.previsao(xmlPrevisaoSaoPaulo);
    final momento = DateTime(2026, 11, 16, 15, 30);
    await armazenamento.salvarPrevisao(_sp, previsao, agora: momento);

    final salva = await armazenamento.previsaoSalva(_sp);
    expect(salva, isNotNull);
    expect(salva!.salvaEm, momento);
    expect(salva.previsao.dias, hasLength(4));
    expect(salva.previsao.dias[2].iuv, 11.0);
    expect(salva.previsao.atualizacao, DateTime(2026, 11, 16));
    expect(await armazenamento.previsaoSalva(_campinas), isNull);
  });

  test('dados corrompidos são ignorados sem erro', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('favoritas', '{nao e json');
    await prefs.setString('historico', '[{"id": 3}, "x", {"id":"9","nome":"Ok"}]');
    await prefs.setString('previsao_244', '{"salvaEm": 1}');

    expect(await armazenamento.favoritas(), isEmpty);
    expect((await armazenamento.historico()).single.nome, 'Ok');
    expect(await armazenamento.previsaoSalva(_sp), isNull);
  });
}
