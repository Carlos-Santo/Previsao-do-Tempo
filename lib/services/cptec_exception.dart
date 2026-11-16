/// Tipos de falha tratados pelo aplicativo.
enum TipoFalha {
  /// Sem internet, DNS falhou, tempo esgotado etc.
  semConexao,

  /// O CPTEC respondeu com erro HTTP (5xx, 404, 429...).
  servicoIndisponivel,

  /// A resposta chegou, mas não é um XML no formato esperado.
  respostaInvalida,
}

class CptecException implements Exception {
  const CptecException(this.tipo, this.mensagem);

  final TipoFalha tipo;

  /// Mensagem pronta para exibir ao usuário.
  final String mensagem;

  @override
  String toString() => 'CptecException($tipo): $mensagem';
}
