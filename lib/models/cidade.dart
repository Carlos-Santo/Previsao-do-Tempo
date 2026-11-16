/// Localidade retornada pelo serviço `listaCidades` do CPTEC/INPE.
///
/// O [id] é o identificador fornecido pelo próprio serviço e é ele que
/// é usado na consulta de previsão.
class Cidade {
  const Cidade({required this.id, required this.nome, required this.uf});

  final String id;
  final String nome;
  final String uf;

  /// Texto no formato "Nome - UF" (ou só o nome quando a UF não veio).
  String get nomeCompleto => uf.isEmpty ? nome : '$nome - $uf';

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'uf': uf};

  /// Retorna `null` quando o JSON salvo está incompleto ou corrompido.
  static Cidade? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final nome = json['nome'];
    final uf = json['uf'];
    if (id is! String || id.isEmpty || nome is! String || nome.isEmpty) {
      return null;
    }
    return Cidade(id: id, nome: nome, uf: uf is String ? uf : '');
  }

  @override
  bool operator ==(Object other) => other is Cidade && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Cidade($id, $nomeCompleto)';
}
