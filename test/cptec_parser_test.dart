import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_do_tempo/services/cptec_exception.dart';
import 'package:previsao_do_tempo/services/cptec_parser.dart';
import 'package:previsao_do_tempo/utils/condicoes_tempo.dart';

import 'fixtures.dart';

void main() {
  group('decodificar', () {
    test('lê acentos de uma resposta em ISO-8859-1', () {
      final bytes = latin1.encode(xmlCidadesSaoPaulo);
      final texto = CptecParser.decodificar(bytes,
          contentType: 'text/xml;charset=ISO-8859-1');
      expect(texto, contains('São Paulo das Missões'));
    });

    test('respeita UTF-8 quando o cabeçalho indica', () {
      final bytes = utf8.encode('<a>Olivença</a>');
      expect(
        CptecParser.decodificar(bytes, contentType: 'text/xml; charset=UTF-8'),
        '<a>Olivença</a>',
      );
    });
  });

  group('cidades', () {
    test('extrai nome, UF e o identificador do serviço', () {
      final cidades = CptecParser.cidades(xmlCidadesSaoPaulo);
      expect(cidades, hasLength(4));
      expect(cidades.first.id, '244');
      expect(cidades.first.nome, 'São Paulo');
      expect(cidades.first.uf, 'SP');
      expect(cidades[2].nomeCompleto, 'São Paulo de Olivença - AM');
    });

    test('lista vazia quando nada é encontrado', () {
      expect(CptecParser.cidades(xmlCidadesVazio), isEmpty);
    });

    test('ignora itens sem id ou nome e repetidos', () {
      final cidades = CptecParser.cidades('<cidades>'
          '<cidade><nome>Sem id</nome><uf>SP</uf></cidade>'
          '<cidade><nome>null</nome><uf>SP</uf><id>1</id></cidade>'
          '<cidade><nome>Santos</nome><id>2</id></cidade>'
          '<cidade><nome>Santos</nome><uf>SP</uf><id>2</id></cidade>'
          '</cidades>');
      expect(cidades, hasLength(1));
      expect(cidades.single.nome, 'Santos');
      expect(cidades.single.uf, '');
    });

    test('XML malformado gera respostaInvalida', () {
      expect(
        () => CptecParser.cidades('<html><body>Erro 502'),
        throwsA(isA<CptecException>()
            .having((e) => e.tipo, 'tipo', TipoFalha.respostaInvalida)),
      );
    });

    test('raiz inesperada gera respostaInvalida', () {
      expect(
        () => CptecParser.cidades('<html><body>Manutenção</body></html>'),
        throwsA(isA<CptecException>()
            .having((e) => e.tipo, 'tipo', TipoFalha.respostaInvalida)),
      );
    });
  });

  group('previsao', () {
    test('lê os quatro dias, atualização e índice UV', () {
      final p = CptecParser.previsao(xmlPrevisaoSaoPaulo);
      expect(p.nome, 'São Paulo');
      expect(p.uf, 'SP');
      expect(p.atualizacao, DateTime(2026, 11, 16));
      expect(p.dias, hasLength(4));

      final primeiro = p.dias.first;
      expect(primeiro.data, DateTime(2026, 11, 17));
      expect(primeiro.siglaTempo, 'pn');
      expect(primeiro.maxima, 27);
      expect(primeiro.minima, 18);
      // 0.0 significa índice não disponível.
      expect(primeiro.iuv, isNull);
      expect(p.dias[2].iuv, 11.0);
    });

    test('código inexistente (campos "null") resulta em previsão vazia', () {
      final p = CptecParser.previsao(xmlPrevisaoNula);
      expect(p.vazia, isTrue);
      expect(p.nome, isNull);
      expect(p.atualizacao, isNull);
    });

    test('campos ausentes ou inválidos não quebram a leitura', () {
      final p = CptecParser.previsao('<cidade><nome>X</nome>'
          '<previsao><dia>2026-11-17</dia><maxima>abc</maxima></previsao>'
          '<previsao><tempo>ps</tempo><minima>12.6</minima><iuv>x</iuv></previsao>'
          '</cidade>');
      expect(p.dias, hasLength(2));
      expect(p.dias[0].maxima, isNull);
      expect(p.dias[0].siglaTempo, isNull);
      expect(p.dias[1].data, isNull);
      expect(p.dias[1].minima, 13);
      expect(p.dias[1].iuv, isNull);
      expect(p.uf, isNull);
    });
  });

  group('condições do tempo', () {
    test('converte siglas da documentação do CPTEC', () {
      expect(condicaoPorSigla('pn').descricao, 'Parcialmente nublado');
      expect(condicaoPorSigla('PS').descricao, 'Predomínio de sol');
      expect(condicaoPorSigla('t').descricao, 'Tempestade');
      expect(condicoesTempo, hasLength(40));
    });

    test('sigla ausente ou desconhecida não gera erro', () {
      expect(condicaoPorSigla(null).descricao, 'Condição não informada');
      expect(condicaoPorSigla('zz').descricao, contains('zz'));
    });

    test('categorias do índice UV', () {
      expect(categoriaUv(2).nome, 'Baixo');
      expect(categoriaUv(5).nome, 'Moderado');
      expect(categoriaUv(7.5).nome, 'Alto');
      expect(categoriaUv(10).nome, 'Muito alto');
      expect(categoriaUv(11).nome, 'Extremo');
    });
  });
}
