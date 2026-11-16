/// Previsão de um único dia (elemento `<previsao>` do XML do CPTEC).
///
/// Todos os campos são opcionais porque o serviço pode omiti-los ou
/// devolvê-los com o texto "null".
class PrevisaoDia {
  const PrevisaoDia({
    this.data,
    this.siglaTempo,
    this.maxima,
    this.minima,
    this.iuv,
  });

  final DateTime? data;

  /// Sigla da condição do tempo (ex.: "pn", "c", "ps").
  final String? siglaTempo;

  /// Temperatura máxima em °C.
  final int? maxima;

  /// Temperatura mínima em °C.
  final int? minima;

  /// Índice ultravioleta. `null` quando o serviço não informa o índice
  /// (o CPTEC envia "0.0" nesse caso).
  final double? iuv;

  /// Um dia só é exibido quando traz alguma informação útil.
  bool get temDados =>
      data != null || siglaTempo != null || maxima != null || minima != null;

  Map<String, dynamic> toJson() => {
        'data': data?.toIso8601String(),
        'tempo': siglaTempo,
        'maxima': maxima,
        'minima': minima,
        'iuv': iuv,
      };

  static PrevisaoDia? fromJson(Object? json) {
    if (json is! Map) return null;
    final data = json['data'];
    final tempo = json['tempo'];
    final maxima = json['maxima'];
    final minima = json['minima'];
    final iuv = json['iuv'];
    return PrevisaoDia(
      data: data is String ? DateTime.tryParse(data) : null,
      siglaTempo: tempo is String ? tempo : null,
      maxima: maxima is num ? maxima.toInt() : null,
      minima: minima is num ? minima.toInt() : null,
      iuv: iuv is num ? iuv.toDouble() : null,
    );
  }
}

/// Resposta completa do serviço de previsão para quatro dias.
class PrevisaoCidade {
  const PrevisaoCidade({
    required this.nome,
    required this.uf,
    required this.atualizacao,
    required this.dias,
  });

  final String? nome;
  final String? uf;

  /// Data de atualização informada pelo CPTEC (`<atualizacao>`).
  final DateTime? atualizacao;

  /// Apenas os dias que trouxeram dados.
  final List<PrevisaoDia> dias;

  bool get vazia => dias.isEmpty;

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'uf': uf,
        'atualizacao': atualizacao?.toIso8601String(),
        'dias': dias.map((d) => d.toJson()).toList(),
      };

  static PrevisaoCidade? fromJson(Object? json) {
    if (json is! Map) return null;
    final nome = json['nome'];
    final uf = json['uf'];
    final atualizacao = json['atualizacao'];
    final dias = json['dias'];
    return PrevisaoCidade(
      nome: nome is String ? nome : null,
      uf: uf is String ? uf : null,
      atualizacao:
          atualizacao is String ? DateTime.tryParse(atualizacao) : null,
      dias: dias is List
          ? dias.map(PrevisaoDia.fromJson).whereType<PrevisaoDia>().toList()
          : const [],
    );
  }
}

/// Previsão guardada no dispositivo, com o momento em que foi salva.
class PrevisaoSalva {
  const PrevisaoSalva({required this.previsao, required this.salvaEm});

  final PrevisaoCidade previsao;
  final DateTime salvaEm;
}
