import 'dart:convert';

import 'package:xml/xml.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import 'cptec_exception.dart';

/// Funções puras que transformam o XML do CPTEC em modelos.
///
/// Ficam separadas do cliente HTTP para poderem ser testadas sem rede.
class CptecParser {
  const CptecParser._();

  /// O CPTEC responde em ISO-8859-1. Se o cabeçalho indicar UTF-8,
  /// respeitamos; caso contrário decodificamos como Latin-1.
  static String decodificar(List<int> bytes, {String? contentType}) {
    final tipo = contentType?.toLowerCase() ?? '';
    if (tipo.contains('utf-8') || tipo.contains('utf8')) {
      return utf8.decode(bytes, allowMalformed: true);
    }
    return latin1.decode(bytes, allowInvalid: true);
  }

  static List<Cidade> cidades(String xml) {
    final raiz = _raiz(xml, 'cidades');
    final resultado = <Cidade>[];
    final vistos = <String>{};
    for (final elemento in raiz.findElements('cidade')) {
      final id = _texto(elemento, 'id');
      final nome = _texto(elemento, 'nome');
      // Itens sem código ou sem nome não podem ser consultados: ignoramos.
      if (id == null || nome == null || !vistos.add(id)) continue;
      resultado.add(Cidade(id: id, nome: nome, uf: _texto(elemento, 'uf') ?? ''));
    }
    return resultado;
  }

  static PrevisaoCidade previsao(String xml) {
    final raiz = _raiz(xml, 'cidade');
    final dias = raiz
        .findElements('previsao')
        .map(_dia)
        .where((dia) => dia.temDados)
        .toList()
      ..sort((a, b) {
        if (a.data == null || b.data == null) return 0;
        return a.data!.compareTo(b.data!);
      });

    return PrevisaoCidade(
      nome: _texto(raiz, 'nome'),
      uf: _texto(raiz, 'uf'),
      atualizacao: _data(_texto(raiz, 'atualizacao')),
      dias: dias,
    );
  }

  static PrevisaoDia _dia(XmlElement elemento) {
    final iuv = double.tryParse(
        (_texto(elemento, 'iuv') ?? '').replaceAll(',', '.'));
    return PrevisaoDia(
      data: _data(_texto(elemento, 'dia')),
      siglaTempo: _texto(elemento, 'tempo')?.toLowerCase(),
      maxima: _inteiro(_texto(elemento, 'maxima')),
      minima: _inteiro(_texto(elemento, 'minima')),
      // O CPTEC devolve 0.0 quando não tem o índice para a localidade.
      iuv: iuv != null && iuv > 0 ? iuv : null,
    );
  }

  static XmlElement _raiz(String xml, String nomeEsperado) {
    final XmlDocument documento;
    try {
      documento = XmlDocument.parse(xml);
    } on XmlException {
      throw const CptecException(
        TipoFalha.respostaInvalida,
        'O CPTEC/INPE enviou uma resposta que não pôde ser lida.',
      );
    }
    final raiz = documento.rootElement;
    if (raiz.name.local != nomeEsperado) {
      throw const CptecException(
        TipoFalha.respostaInvalida,
        'O CPTEC/INPE enviou uma resposta em formato inesperado.',
      );
    }
    return raiz;
  }

  /// Texto do filho [tag], ou `null` se ausente, vazio ou "null".
  static String? _texto(XmlElement pai, String tag) {
    final valor = pai.getElement(tag)?.innerText.trim();
    if (valor == null || valor.isEmpty || valor.toLowerCase() == 'null') {
      return null;
    }
    return valor;
  }

  static int? _inteiro(String? valor) {
    if (valor == null) return null;
    return int.tryParse(valor) ?? double.tryParse(valor)?.round();
  }

  static DateTime? _data(String? valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor);
  }
}
