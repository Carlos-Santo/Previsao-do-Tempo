import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_do_tempo/main.dart';
import 'package:previsao_do_tempo/models/cidade.dart';
import 'package:previsao_do_tempo/screens/grafico_screen.dart';
import 'package:previsao_do_tempo/services/armazenamento_local.dart';
import 'package:previsao_do_tempo/services/cptec_parser.dart';
import 'package:previsao_do_tempo/services/cptec_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fixtures.dart';

void main() {
  late ArmazenamentoLocal armazenamento;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    armazenamento = ArmazenamentoLocal(SharedPreferencesAsync());
  });

  Future<void> abrirApp(WidgetTester tester, http.Client client) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PrevisaoApp(
      servico: CptecService(client: client),
      armazenamento: armazenamento,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pesquisar(WidgetTester tester, String termo) async {
    await tester.enterText(find.byType(TextField), termo);
    await tester.tap(find.text('Pesquisar'));
    await tester.pumpAndSettle();
  }

  testWidgets('pesquisa, abre a previsão e navega para os gráficos',
      (tester) async {
    await abrirApp(tester, clienteFalso());
    expect(find.text('Fonte dos dados: CPTEC/INPE'), findsOneWidget);

    await pesquisar(tester, 'São Paulo');
    expect(find.text('4 localidades encontradas'), findsOneWidget);
    expect(find.text('São Paulo das Missões'), findsOneWidget);
    expect(find.text('RS'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'São Paulo'));
    await tester.pumpAndSettle();

    expect(find.text('São Paulo - SP'), findsOneWidget);
    expect(find.text('Atualizado pelo CPTEC/INPE em 16/11/2026'), findsOneWidget);
    expect(find.text('Parcialmente nublado'), findsOneWidget);
    expect(find.text('17/11/2026'), findsOneWidget);
    expect(find.text('27 °C'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Tempestade'), 200);
    expect(find.text('UV 7.5 · Alto'), findsOneWidget);
    expect(find.text('UV não disponível'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Ver gráficos detalhados'), -200);
    await tester.tap(find.text('Ver gráficos detalhados'));
    await tester.pumpAndSettle();
    expect(find.byType(GraficoScreen), findsOneWidget);
    expect(find.text('Amplitude térmica'), findsOneWidget);
    expect(find.text('31 °C'), findsWidgets);

    // Ao voltar para a tela inicial, a cidade aparece no histórico.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Limpar'));
    await tester.pumpAndSettle();
    expect(find.text('Consultadas recentemente'), findsOneWidget);
  });

  testWidgets('informa quando nenhuma cidade é encontrada', (tester) async {
    await abrirApp(tester, clienteFalso(cidades: xmlCidadesVazio));
    await pesquisar(tester, 'Xyzabc');
    expect(find.text('Nenhuma cidade encontrada'), findsOneWidget);
    expect(find.textContaining('"Xyzabc"'), findsOneWidget);
  });

  testWidgets('falha de conexão na pesquisa permite tentar novamente',
      (tester) async {
    var falhar = true;
    final client = MockClient((req) async {
      if (falhar) throw http.ClientException('offline');
      return respostaLatin1(xmlCidadesSaoPaulo);
    });
    await abrirApp(tester, client);
    await pesquisar(tester, 'São Paulo');
    expect(find.text('Não foi possível pesquisar'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);

    falhar = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('4 localidades encontradas'), findsOneWidget);
  });

  testWidgets('mostra mensagem quando não há previsão disponível',
      (tester) async {
    await abrirApp(tester, clienteFalso(previsao: xmlPrevisaoNula));
    await pesquisar(tester, 'São Paulo');
    await tester.tap(find.widgetWithText(ListTile, 'São Paulo'));
    await tester.pumpAndSettle();
    expect(find.text('Não há previsão disponível'), findsOneWidget);
  });

  testWidgets('sem conexão, exibe a previsão salva no aparelho',
      (tester) async {
    const sp = Cidade(id: '244', nome: 'São Paulo', uf: 'SP');
    await armazenamento.salvarPrevisao(
      sp,
      CptecParser.previsao(xmlPrevisaoSaoPaulo),
      agora: DateTime(2026, 11, 16, 9, 5),
    );
    await armazenamento.registrarNoHistorico(sp);

    await abrirApp(tester,
        MockClient((_) async => throw http.ClientException('offline')));
    await tester.tap(find.text('São Paulo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('previsão salva no aparelho em 16/11/2026 às 09:05'),
        findsOneWidget);
    expect(find.text('Parcialmente nublado'), findsOneWidget);
  });

  testWidgets('serviço fora do ar e sem cópia local mostra erro',
      (tester) async {
    await abrirApp(
        tester,
        MockClient((req) async => req.url.path.contains('listaCidades')
            ? respostaLatin1(xmlCidadesSaoPaulo)
            : http.Response('', 500)));
    await pesquisar(tester, 'São Paulo');
    await tester.tap(find.widgetWithText(ListTile, 'São Paulo'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar a previsão'), findsOneWidget);
    expect(find.textContaining('indisponível'), findsOneWidget);
  });

  testWidgets('favoritar aparece na tela inicial', (tester) async {
    await abrirApp(tester, clienteFalso());
    await pesquisar(tester, 'São Paulo');
    await tester.tap(find.widgetWithText(ListTile, 'São Paulo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar às favoritas'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remover das favoritas'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Limpar'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritas'), findsOneWidget);
    expect(await armazenamento.favoritas(), hasLength(1));
  });
}
