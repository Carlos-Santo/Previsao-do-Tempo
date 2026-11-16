import 'package:flutter/material.dart';

import '../models/cidade.dart';
import '../services/armazenamento_local.dart';
import '../services/cptec_exception.dart';
import '../services/cptec_service.dart';
import '../widgets/comuns.dart';
import 'previsao_screen.dart';

/// Tela inicial: pesquisa de cidades, favoritas e consultas recentes.
class BuscaScreen extends StatefulWidget {
  const BuscaScreen({super.key, required this.servico, required this.armazenamento});

  final CptecService servico;
  final ArmazenamentoLocal armazenamento;

  @override
  State<BuscaScreen> createState() => _BuscaScreenState();
}

class _BuscaScreenState extends State<BuscaScreen> {
  final _controlador = TextEditingController();

  bool _carregando = false;
  String? _termoPesquisado;
  List<Cidade>? _resultados;
  CptecException? _erro;
  int _pesquisaAtual = 0;

  List<Cidade> _favoritas = [];
  List<Cidade> _historico = [];

  @override
  void initState() {
    super.initState();
    _carregarSalvos();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _carregarSalvos() async {
    final favoritas = await widget.armazenamento.favoritas();
    final historico = await widget.armazenamento.historico();
    if (!mounted) return;
    setState(() {
      _favoritas = favoritas;
      _historico = historico;
    });
  }

  Future<void> _pesquisar() async {
    final termo = _controlador.text.trim();
    FocusScope.of(context).unfocus();
    if (termo.length < 2) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Digite pelo menos 2 letras do nome da cidade.')));
      return;
    }

    // Garante que só a resposta da última pesquisa seja exibida.
    final pesquisa = ++_pesquisaAtual;
    setState(() {
      _carregando = true;
      _erro = null;
      _termoPesquisado = termo;
    });

    try {
      final cidades = await widget.servico.buscarCidades(termo);
      if (!mounted || pesquisa != _pesquisaAtual) return;
      setState(() => _resultados = cidades);
    } on CptecException catch (e) {
      if (!mounted || pesquisa != _pesquisaAtual) return;
      setState(() {
        _erro = e;
        _resultados = null;
      });
    } finally {
      if (mounted && pesquisa == _pesquisaAtual) {
        setState(() => _carregando = false);
      }
    }
  }

  void _limparPesquisa() {
    _pesquisaAtual++;
    _controlador.clear();
    setState(() {
      _carregando = false;
      _resultados = null;
      _erro = null;
      _termoPesquisado = null;
    });
  }

  Future<void> _abrirPrevisao(Cidade cidade) async {
    await widget.armazenamento.registrarNoHistorico(cidade);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PrevisaoScreen(
        cidade: cidade,
        servico: widget.servico,
        armazenamento: widget.armazenamento,
      ),
    ));
    // Favoritas podem ter mudado na tela de previsão.
    await _carregarSalvos();
  }

  Future<void> _limparHistorico() async {
    await widget.armazenamento.limparHistorico();
    await _carregarSalvos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previsão do Tempo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controlador,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _pesquisar(),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Pesquisar cidade (ex.: Campinas)',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28))),
                suffixIcon: _controlador.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        icon: const Icon(Icons.close),
                        onPressed: _limparPesquisa,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _carregando ? null : _pesquisar,
                icon: const Icon(Icons.travel_explore),
                label: const Text('Pesquisar'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _conteudo()),
          const FonteDados(),
        ],
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    final erro = _erro;
    if (erro != null) {
      return EstadoMensagem(
        icone: erro.tipo == TipoFalha.semConexao
            ? Icons.wifi_off
            : Icons.cloud_off,
        titulo: 'Não foi possível pesquisar',
        mensagem: erro.mensagem,
        rotuloAcao: 'Tentar novamente',
        aoAgir: _pesquisar,
      );
    }
    final resultados = _resultados;
    if (resultados != null) {
      if (resultados.isEmpty) {
        return EstadoMensagem(
          icone: Icons.location_off,
          titulo: 'Nenhuma cidade encontrada',
          mensagem: 'Não encontramos localidades para "$_termoPesquisado". '
              'Confira a grafia ou tente só o começo do nome.',
        );
      }
      return ListView(
        children: [
          _Titulo(
              '${resultados.length} '
              '${resultados.length == 1 ? 'localidade encontrada' : 'localidades encontradas'}'),
          for (final cidade in resultados) _itemCidade(cidade),
        ],
      );
    }
    return _inicio();
  }

  Widget _inicio() {
    if (_favoritas.isEmpty && _historico.isEmpty) {
      return const EstadoMensagem(
        icone: Icons.wb_sunny_outlined,
        titulo: 'Consulte a previsão do tempo',
        mensagem: 'Pesquise o nome de uma cidade brasileira para ver a '
            'previsão dos próximos quatro dias.',
      );
    }
    return ListView(
      children: [
        if (_favoritas.isNotEmpty) ...[
          const _Titulo('Favoritas'),
          for (final cidade in _favoritas)
            _itemCidade(cidade, icone: Icons.star, corIcone: Colors.amber),
        ],
        if (_historico.isNotEmpty) ...[
          _Titulo('Consultadas recentemente',
              acao: TextButton(
                  onPressed: _limparHistorico, child: const Text('Limpar'))),
          for (final cidade in _historico)
            _itemCidade(cidade, icone: Icons.history),
        ],
      ],
    );
  }

  Widget _itemCidade(Cidade cidade,
      {IconData icone = Icons.location_city, Color? corIcone}) {
    return ListTile(
      leading: Icon(icone, color: corIcone),
      title: Text(cidade.nome),
      subtitle: Text(cidade.uf.isEmpty ? 'UF não informada' : cidade.uf),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _abrirPrevisao(cidade),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, {this.acao});

  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(texto,
                style: tema.textTheme.titleSmall
                    ?.copyWith(color: tema.colorScheme.primary)),
          ),
          ?acao,
        ],
      ),
    );
  }
}
