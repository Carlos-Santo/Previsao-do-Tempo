// Gera as capturas de tela usadas no README.
//
//   flutter test --update-goldens test_capturas
//
// As telas são as do aplicativo, alimentadas com respostas de exemplo no
// formato do CPTEC/INPE (veja test/fixtures.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_do_tempo/main.dart';
import 'package:previsao_do_tempo/models/cidade.dart';
import 'package:previsao_do_tempo/services/armazenamento_local.dart';
import 'package:previsao_do_tempo/services/cptec_parser.dart';
import 'package:previsao_do_tempo/services/cptec_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../test/fixtures.dart';

const _destino = '../docs/capturas';

/// Carrega a Roboto que acompanha o SDK do Flutter e os ícones do app,
/// para que as capturas não usem a fonte de teste (blocos).
Future<void> _carregarFontes() async {
  final raizFlutter = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent
          .parent.path;
  final pasta = '$raizFlutter/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final peso in ['light', 'regular', 'medium', 'bold']) {
    final bytes = File('$pasta/roboto-$peso.ttf').readAsBytesSync();
    roboto.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();

  final manifesto = jsonDecode(await rootBundle.loadString('FontManifest.json'))
      as List<dynamic>;
  for (final familia in manifesto.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(familia['family'] as String);
    for (final fonte in (familia['fonts'] as List).cast<Map>()) {
      loader.addFont(rootBundle.load(fonte['asset'] as String));
    }
    await loader.load();
  }
}

const _cidadesCampinas =
    "<?xml version='1.0' encoding='ISO-8859-1'?><cidades>"
    '<cidade><nome>Campinas</nome><uf>SP</uf><id>1209</id></cidade>'
    '<cidade><nome>Campinas do Piauí</nome><uf>PI</uf><id>1210</id></cidade>'
    '<cidade><nome>Campinas do Sul</nome><uf>RS</uf><id>1211</id></cidade>'
    '<cidade><nome>Campinápolis</nome><uf>MT</uf><id>1208</id></cidade>'
    '<cidade><nome>Campinorte</nome><uf>GO</uf><id>1212</id></cidade>'
    '</cidades>';

void main() {
  setUpAll(_carregarFontes);

  late ArmazenamentoLocal armazenamento;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    armazenamento = ArmazenamentoLocal(SharedPreferencesAsync());
  });

  Future<void> abrir(WidgetTester tester,
      {http.Client? client, ThemeMode tema = ThemeMode.light}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PrevisaoApp(
      servico: CptecService(client: client ?? clienteFalso(cidades: _cidadesCampinas)),
      armazenamento: armazenamento,
      temaForcado: tema,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pesquisar(WidgetTester tester, String termo) async {
    await tester.enterText(find.byType(TextField), termo);
    await tester.tap(find.text('Pesquisar'));
    await tester.pumpAndSettle();
  }

  Future<void> abrirCidade(WidgetTester tester, String nome) async {
    await tester.tap(find.widgetWithText(ListTile, nome).first);
    await tester.pumpAndSettle();
  }

  Future<void> capturar(String nome) => expectLater(
      find.byType(MaterialApp), matchesGoldenFile('$_destino/$nome.png'));

  const sp = Cidade(id: '244', nome: 'São Paulo', uf: 'SP');
  const rio = Cidade(id: '241', nome: 'Rio de Janeiro', uf: 'RJ');
  const campinas = Cidade(id: '1209', nome: 'Campinas', uf: 'SP');

  testWidgets('01 tela inicial', (tester) async {
    await armazenamento.alternarFavorita(sp);
    await armazenamento.alternarFavorita(rio);
    for (final c in [rio, campinas, sp]) {
      await armazenamento.registrarNoHistorico(c);
    }
    await abrir(tester);
    await capturar('01_inicio');
  });

  testWidgets('02 resultados da pesquisa', (tester) async {
    await abrir(tester);
    await pesquisar(tester, 'Campinas');
    await capturar('02_pesquisa');
  });

  testWidgets('03 e 04 previsão', (tester) async {
    await abrir(tester, client: clienteFalso());
    await pesquisar(tester, 'São Paulo');
    await abrirCidade(tester, 'São Paulo');
    await capturar('03_previsao');
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await capturar('04_previsao_dias');
  });

  testWidgets('05 gráficos', (tester) async {
    await abrir(tester, client: clienteFalso());
    await pesquisar(tester, 'São Paulo');
    await abrirCidade(tester, 'São Paulo');
    await tester.tap(find.text('Ver gráficos detalhados'));
    await tester.pumpAndSettle();
    await capturar('05_graficos');
  });

  testWidgets('06 sem conexão com previsão salva', (tester) async {
    await armazenamento.salvarPrevisao(
        sp, CptecParser.previsao(xmlPrevisaoSaoPaulo),
        agora: DateTime(2026, 11, 16, 9, 5));
    await armazenamento.registrarNoHistorico(sp);
    await abrir(tester,
        client: MockClient((_) async => throw http.ClientException('offline')));
    await abrirCidade(tester, 'São Paulo');
    // Fecha o aviso temporário para a captura ficar limpa.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await capturar('06_sem_conexao');
  });

  testWidgets('07 nenhuma cidade encontrada', (tester) async {
    await abrir(tester, client: clienteFalso(cidades: xmlCidadesVazio));
    await pesquisar(tester, 'Cidadezinha');
    await capturar('07_nenhuma_cidade');
  });

  testWidgets('08 tema escuro', (tester) async {
    await abrir(tester, client: clienteFalso(), tema: ThemeMode.dark);
    await pesquisar(tester, 'São Paulo');
    await abrirCidade(tester, 'São Paulo');
    await capturar('08_tema_escuro');
  });
}
