import 'package:flutter/material.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/armazenamento_local.dart';
import '../services/cptec_exception.dart';
import '../services/cptec_service.dart';
import '../utils/formatadores.dart';
import '../widgets/card_dia_previsao.dart';
import '../widgets/comuns.dart';
import '../widgets/grafico_temperaturas.dart';
import 'grafico_screen.dart';

/// Previsão de quatro dias da cidade selecionada.
class PrevisaoScreen extends StatefulWidget {
  const PrevisaoScreen({
    super.key,
    required this.cidade,
    required this.servico,
    required this.armazenamento,
    this.hoje,
  });

  final Cidade cidade;
  final CptecService servico;
  final ArmazenamentoLocal armazenamento;

  /// Data de referência para "Hoje"/"Amanhã" (útil em testes).
  final DateTime? hoje;

  @override
  State<PrevisaoScreen> createState() => _PrevisaoScreenState();
}

class _PrevisaoScreenState extends State<PrevisaoScreen> {
  bool _carregando = true;
  bool _favorita = false;
  PrevisaoCidade? _previsao;

  /// Preenchido quando a previsão exibida veio do armazenamento local.
  DateTime? _salvaEm;
  CptecException? _erro;

  @override
  void initState() {
    super.initState();
    widget.armazenamento.ehFavorita(widget.cidade).then((favorita) {
      if (mounted) setState(() => _favorita = favorita);
    });
    _carregar();
  }

  Future<void> _carregar({bool avisarSucesso = false}) async {
    setState(() => _carregando = true);
    try {
      final previsao = await widget.servico.buscarPrevisao(widget.cidade.id);
      if (!previsao.vazia) {
        await widget.armazenamento.salvarPrevisao(widget.cidade, previsao);
      }
      if (!mounted) return;
      setState(() {
        _previsao = previsao;
        _salvaEm = null;
        _erro = null;
      });
      if (avisarSucesso && !previsao.vazia) {
        _mostrarAviso('Previsão atualizada.');
      }
    } on CptecException catch (e) {
      final salva = await widget.armazenamento.previsaoSalva(widget.cidade);
      if (!mounted) return;
      setState(() {
        _erro = e;
        // Mantém o que já estava na tela; se não houver, usa a cópia local.
        if (_previsao == null || _salvaEm != null) {
          _previsao = salva?.previsao;
          _salvaEm = salva?.salvaEm;
        }
      });
      if (_previsao != null) _mostrarAviso(e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _alternarFavorita() async {
    final favorita = await widget.armazenamento.alternarFavorita(widget.cidade);
    if (!mounted) return;
    setState(() => _favorita = favorita);
    _mostrarAviso(favorita
        ? '${widget.cidade.nome} adicionada às favoritas.'
        : '${widget.cidade.nome} removida das favoritas.');
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _abrirGrafico(PrevisaoCidade previsao) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => GraficoScreen(cidade: widget.cidade, previsao: previsao),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cidade.nomeCompleto),
        actions: [
          IconButton(
            tooltip: _favorita ? 'Remover das favoritas' : 'Adicionar às favoritas',
            icon: Icon(_favorita ? Icons.star : Icons.star_border),
            onPressed: _alternarFavorita,
          ),
          IconButton(
            tooltip: 'Atualizar previsão',
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : () => _carregar(avisarSucesso: true),
          ),
        ],
        bottom: _carregando && _previsao != null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    final previsao = _previsao;

    if (previsao == null) {
      if (_carregando) {
        return const Center(child: CircularProgressIndicator());
      }
      final erro = _erro;
      return Column(
        children: [
          Expanded(
            child: EstadoMensagem(
              icone: switch (erro?.tipo) {
                TipoFalha.semConexao => Icons.wifi_off,
                TipoFalha.servicoIndisponivel => Icons.cloud_off,
                _ => Icons.error_outline,
              },
              titulo: 'Não foi possível carregar a previsão',
              mensagem: erro?.mensagem ?? 'Erro desconhecido.',
              rotuloAcao: 'Tentar novamente',
              aoAgir: _carregar,
            ),
          ),
          const FonteDados(),
        ],
      );
    }

    if (previsao.vazia) {
      return Column(
        children: [
          Expanded(
            child: EstadoMensagem(
              icone: Icons.cloud_queue,
              titulo: 'Não há previsão disponível',
              mensagem: 'O CPTEC/INPE não forneceu previsão para '
                  '${widget.cidade.nomeCompleto} no momento. '
                  'Tente novamente mais tarde.',
              rotuloAcao: 'Tentar novamente',
              aoAgir: _carregando ? null : _carregar,
            ),
          ),
          const FonteDados(),
        ],
      );
    }

    final tema = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => _carregar(avisarSucesso: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          if (_salvaEm != null) _avisoOffline(_salvaEm!),
          _cabecalho(previsao),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Temperaturas',
                              style: tema.textTheme.titleMedium),
                        ),
                        const LegendaTemperaturas(),
                      ],
                    ),
                  ),
                  GraficoTemperaturas(dias: previsao.dias, altura: 190),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _abrirGrafico(previsao),
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Ver gráficos detalhados'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Previsão para ${previsao.dias.length} '
                '${previsao.dias.length == 1 ? 'dia' : 'dias'}',
                style: tema.textTheme.titleSmall
                    ?.copyWith(color: tema.colorScheme.primary)),
          ),
          for (final dia in previsao.dias)
            CardDiaPrevisao(dia: dia, hoje: widget.hoje),
          const FonteDados(),
        ],
      ),
    );
  }

  Widget _cabecalho(PrevisaoCidade previsao) {
    final tema = Theme.of(context);
    final atualizacao = previsao.atualizacao;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(Icons.update, size: 18, color: tema.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              atualizacao == null
                  ? 'Data de atualização não informada pelo CPTEC/INPE'
                  : 'Atualizado pelo CPTEC/INPE em ${formatarData(atualizacao)}',
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoOffline(DateTime salvaEm) {
    final tema = Theme.of(context);
    return Card(
      color: tema.colorScheme.tertiaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: tema.colorScheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sem resposta do CPTEC/INPE. Exibindo a previsão salva no '
                'aparelho em ${formatarDataHora(salvaEm)}.',
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
