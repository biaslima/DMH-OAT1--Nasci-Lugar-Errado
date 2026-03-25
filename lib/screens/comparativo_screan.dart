import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/models/usuario_model.dart';
import '../data/models/vida_alternativa_model.dart';
import '../providers/vida_provider.dart';
import '../services/countries_service.dart';

class ComparativoScreen extends StatefulWidget {
  final UsuarioModel usuario;
  final VidaAlternativaModel vida;

  const ComparativoScreen({
    super.key,
    required this.usuario,
    required this.vida,
  });

  @override
  State<ComparativoScreen> createState() => _ComparativoScreenState();
}

class _ComparativoScreenState extends State<ComparativoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  bool _salvo = false;
  bool _salvando = false;

  // Dados reais do país de origem
  Map<String, dynamic>? _paisOrigem;
  bool _loadingOrigem = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _carregarPaisOrigem();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Busca os dados do país de origem do usuário usando o CountriesService.
  /// O service tem cache, então se já foi chamado antes é instantâneo.
  Future<void> _carregarPaisOrigem() async {
    try {
      final todos = await CountriesService().getAllCountries();
      final code = widget.usuario.paisOrigemCode.toUpperCase();
      final encontrado = todos.firstWhere(
            (p) => (p['cca2'] as String?)?.toUpperCase() == code,
        orElse: () => {},
      );
      setState(() {
        _paisOrigem = encontrado.isNotEmpty ? encontrado : null;
        _loadingOrigem = false;
      });
    } catch (_) {
      setState(() => _loadingOrigem = false);
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final ok = await context.read<VidaProvider>().salvarVidaAtual();
    if (!mounted) return;
    setState(() {
      _salvando = false;
      _salvo = ok;
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vida salva no histórico!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.go('/historico');
      });
    }
  }

  String _formatarPopulacao(int? pop) {
    if (pop == null) return '—';
    if (pop >= 1000000000) return '${(pop / 1e9).toStringAsFixed(1)}B';
    if (pop >= 1000000) return '${(pop / 1e6).toStringAsFixed(1)}M';
    if (pop >= 1000) return '${(pop / 1000).toStringAsFixed(0)}k';
    return pop.toString();
  }

  String _fraseExpectativa() {
    final vidaAlt = widget.vida.expectativaVida ?? 70.0;
    final vidaReal = _expectativaPorRegiao(
        (_paisOrigem?['region'] as String?) ?? '');
    final diff = vidaAlt - vidaReal;
    if (diff.abs() < 1) return 'Expectativa de vida parecida com a sua!';
    final anos = diff.abs().toStringAsFixed(1);
    return diff > 0
        ? 'Você viveria $anos anos a mais! 🎉'
        : 'Você viveria $anos anos a menos.';
  }

  double _expectativaPorRegiao(String regiao) {
    switch (regiao) {
      case 'Europe':   return 78.5;
      case 'Americas': return 74.2;
      case 'Asia':     return 73.8;
      case 'Oceania':  return 77.1;
      case 'Africa':   return 62.7;
      default:         return 70.0;
    }
  }

  Map<String, dynamic> _parseClima() {
    try {
      return jsonDecode(widget.vida.climaNascimento ?? '{}');
    } catch (_) {
      return {};
    }
  }

  // Extrai campos do país de origem do Map da API
  String _origemCapital() {
    final cap = _paisOrigem?['capital'] as List?;
    return cap?.isNotEmpty == true ? cap!.first as String : '—';
  }

  String _origemIdioma() {
    final langs = _paisOrigem?['languages'] as Map?;
    return langs?.values.first?.toString() ?? '—';
  }

  String _origemMoeda() {
    final curr = _paisOrigem?['currencies'] as Map?;
    if (curr == null || curr.isEmpty) return '—';
    final key = curr.keys.first as String;
    final nome = (curr[key] as Map?)?['name'] as String? ?? key;
    return '$nome ($key)';
  }

  String _origemPopulacao() =>
      _formatarPopulacao(_paisOrigem?['population'] as int?);

  double _origemExpectativa() =>
      _expectativaPorRegiao(_paisOrigem?['region'] as String? ?? '');

  String? _origemBandeiraUrl() =>
      (_paisOrigem?['flags'] as Map?)?['png'] as String?;

  @override
  Widget build(BuildContext context) {
    final clima = _parseClima();
    final dataNasc = DateFormat('dd/MM/yyyy').format(
      DateTime.parse(widget.usuario.dataNascimento),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0B1E), Color(0xFF1A1040), Color(0xFF12203E)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white70),
                        onPressed: () => context.pop(),
                      ),
                      const Text(
                        'Suas duas vidas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '🎂 Nascido(a) em $dataNasc',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),

                Expanded(
                  child: _loadingOrigem
                      ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7C5CFC)),
                  )
                      : SingleChildScrollView(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _FraseDestaque(texto: _fraseExpectativa()),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Coluna REAL (dados dinâmicos da API)
                            Expanded(
                              child: _ComparativoColuna(
                                titulo: 'Você Real',
                                emoji: '🧑',
                                cor: const Color(0xFF4A90D9),
                                bandeiraUrl: _origemBandeiraUrl(),
                                paisCode: widget.usuario.paisOrigemCode,
                                items: [
                                  _ItemInfo(icone: '🌍', label: 'País',
                                      valor: widget.usuario.paisOrigemNome),
                                  _ItemInfo(icone: '🗓️', label: 'Nascimento',
                                      valor: dataNasc),
                                  _ItemInfo(icone: '👥', label: 'População',
                                      valor: _origemPopulacao()),
                                  _ItemInfo(icone: '📍', label: 'Capital',
                                      valor: _origemCapital()),
                                  _ItemInfo(icone: '🗣️', label: 'Idioma',
                                      valor: _origemIdioma()),
                                  _ItemInfo(icone: '💰', label: 'Moeda',
                                      valor: _origemMoeda()),
                                  _ItemInfo(icone: '❤️', label: 'Expectativa',
                                      valor: '${_origemExpectativa().toStringAsFixed(1)} anos'),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // ── Coluna ALTERNATIVA
                            Expanded(
                              child: _ComparativoColuna(
                                titulo: 'Você Alternativo',
                                emoji: '✨',
                                cor: const Color(0xFF7C5CFC),
                                bandeiraUrl: widget.vida.bandeiraUrl,
                                paisCode: widget.vida.paisCode,
                                items: [
                                  _ItemInfo(icone: '🌍', label: 'País',
                                      valor: widget.vida.paisNome),
                                  _ItemInfo(icone: '🗓️', label: 'Nascimento',
                                      valor: dataNasc),
                                  _ItemInfo(icone: '👥', label: 'População',
                                      valor: _formatarPopulacao(widget.vida.populacao)),
                                  _ItemInfo(icone: '📍', label: 'Capital',
                                      valor: widget.vida.capital ?? '—'),
                                  _ItemInfo(icone: '🗣️', label: 'Idioma',
                                      valor: widget.vida.idioma ?? '—'),
                                  _ItemInfo(icone: '💰', label: 'Moeda',
                                      valor: widget.vida.moeda ?? '—'),
                                  _ItemInfo(icone: '❤️', label: 'Expectativa',
                                      valor: widget.vida.expectativaVida != null
                                          ? '${widget.vida.expectativaVida!.toStringAsFixed(1)} anos'
                                          : '—'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        if (clima.isNotEmpty &&
                            clima['descricao'] !=
                                'Dados climáticos não disponíveis') ...[
                          _ClimaCard(clima: clima, data: dataNasc),
                          const SizedBox(height: 24),
                        ],

                        _BotoesAcao(
                          salvo: _salvo,
                          salvando: _salvando,
                          onSalvar: _salvar,
                          onSortearNovamente: () =>
                              context.go('/sorteio', extra: widget.usuario),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets (inalterados) ────────────────────────────────────────────────

class _FraseDestaque extends StatelessWidget {
  final String texto;
  const _FraseDestaque({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CFC), Color(0xFF4A90D9)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ItemInfo {
  final String icone;
  final String label;
  final String valor;
  const _ItemInfo(
      {required this.icone, required this.label, required this.valor});
}

class _ComparativoColuna extends StatelessWidget {
  final String titulo;
  final String emoji;
  final Color cor;
  final String? bandeiraUrl;
  final String paisCode;
  final List<_ItemInfo> items;

  const _ComparativoColuna({
    required this.titulo,
    required this.emoji,
    required this.cor,
    this.bandeiraUrl,
    required this.paisCode,
    required this.items,
  });

  String _bandeiraPorCodigo(String code) {
    return code.toUpperCase().codeUnits
        .map((c) => String.fromCharCode(c + 127397))
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(titulo,
                    style: TextStyle(
                        color: cor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                if (bandeiraUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: bandeiraUrl!,
                      width: 52,
                      height: 32,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Text(
                          _bandeiraPorCodigo(paisCode),
                          style: const TextStyle(fontSize: 28)),
                    ),
                  )
                else
                  Text(_bandeiraPorCodigo(paisCode),
                      style: const TextStyle(fontSize: 32)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.icone} ${item.label}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(item.valor,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const Divider(color: Colors.white10, height: 10),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClimaCard extends StatelessWidget {
  final Map<String, dynamic> clima;
  final String data;
  const _ClimaCard({required this.clima, required this.data});

  @override
  Widget build(BuildContext context) {
    final temp = clima['temperatura_max'];
    final desc = clima['descricao'] ?? 'Clima não disponível';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌤 Clima no seu dia de nascimento',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                temp != null ? '${(temp as num).toStringAsFixed(0)}°C' : '—',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(desc,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotoesAcao extends StatelessWidget {
  final bool salvo;
  final bool salvando;
  final VoidCallback onSalvar;
  final VoidCallback onSortearNovamente;

  const _BotoesAcao({
    required this.salvo,
    required this.salvando,
    required this.onSalvar,
    required this.onSortearNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: salvo ? null : onSalvar,
            icon: salvando
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : Icon(
                salvo ? Icons.check_circle : Icons.bookmark_add_outlined),
            label: Text(salvo ? 'Vida salva!' : 'Salvar esta vida'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              salvo ? Colors.green[700] : const Color(0xFF7C5CFC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: Colors.green[700],
              disabledForegroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onSortearNovamente,
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Sortear outra vida'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}