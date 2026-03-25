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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Vida salva no histórico!'),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
    final vidaReal = _expectativaReal(
      (_paisOrigem?['region'] as String?) ?? '',
    );
    final diff = vidaAlt - vidaReal;
    if (diff.abs() < 1) return 'Expectativa de vida parecida com a sua!';
    final anos = diff.abs().toStringAsFixed(1);
    return diff > 0
        ? 'Você viveria $anos anos a mais! 🎉'
        : 'Você viveria $anos anos a menos.';
  }

  Map<String, dynamic> _parseClima() {
    try {
      return jsonDecode(widget.vida.climaNascimento ?? '{}');
    } catch (_) {
      return {};
    }
  }

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

  double _expectativaReal(String region) {
    const expectativas = {
      'Africa': 63.0,
      'Americas': 75.0,
      'Asia': 72.0,
      'Europe': 78.0,
      'Oceania': 76.0,
    };
    return expectativas[region] ?? 70.0;
  }

  String _origemPopulacao() =>
      _formatarPopulacao(_paisOrigem?['population'] as int?);

  double _origemExpectativa() =>
      _expectativaReal(_paisOrigem?['region'] as String? ?? '');

  String? _origemBandeiraUrl() =>
      (_paisOrigem?['flags'] as Map?)?['png'] as String?;

  /// Retorna cor e ícone para comparação de expectativa de vida
  ({Color cor, IconData icone, String label}) _expectativaComparacao() {
    final alt = widget.vida.expectativaVida ?? 70.0;
    final real = _expectativaReal((_paisOrigem?['region'] as String?) ?? '');
    final diff = alt - real;
    if (diff.abs() < 1) {
      return (cor: Colors.white54, icone: Icons.remove, label: 'Igual');
    }
    return diff > 0
        ? (
            cor: const Color(0xFF4CAF50),
            icone: Icons.trending_up,
            label: '+${diff.toStringAsFixed(1)} anos',
          )
        : (
            cor: Colors.redAccent,
            icone: Icons.trending_down,
            label: '${diff.toStringAsFixed(1)} anos',
          );
  }

  @override
  Widget build(BuildContext context) {
    final clima = _parseClima();
    final dataNasc = DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.parse(widget.usuario.dataNascimento));

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
                // ── AppBar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white70,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Suas duas vidas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtítulo com data
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        size: 14,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Nascido(a) em $dataNasc',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _loadingOrigem
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C5CFC),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // ── Frase destaque ──────────────────────
                              _FraseDestaque(
                                texto: _fraseExpectativa(),
                                comparacao: _expectativaComparacao(),
                              ),
                              const SizedBox(height: 20),

                              // ── Colunas comparativas ─────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _ComparativoColuna(
                                      titulo: 'Você Real',
                                      emoji: '🧑',
                                      cor: const Color(0xFF4A90D9),
                                      bandeiraUrl: _origemBandeiraUrl(),
                                      paisCode: widget.usuario.paisOrigemCode,
                                      items: [
                                        _ItemInfo(
                                          icone: '🌍',
                                          label: 'País',
                                          valor: widget.usuario.paisOrigemNome,
                                        ),
                                        _ItemInfo(
                                          icone: '🗓️',
                                          label: 'Nascimento',
                                          valor: dataNasc,
                                        ),
                                        _ItemInfo(
                                          icone: '👥',
                                          label: 'População',
                                          valor: _origemPopulacao(),
                                        ),
                                        _ItemInfo(
                                          icone: '📍',
                                          label: 'Capital',
                                          valor: _origemCapital(),
                                        ),
                                        _ItemInfo(
                                          icone: '🗣️',
                                          label: 'Idioma',
                                          valor: _origemIdioma(),
                                        ),
                                        _ItemInfo(
                                          icone: '💰',
                                          label: 'Moeda',
                                          valor: _origemMoeda(),
                                        ),
                                        _ItemInfo(
                                          icone: '❤️',
                                          label: 'Expectativa',
                                          valor:
                                              '${_origemExpectativa().toStringAsFixed(1)} anos',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ComparativoColuna(
                                      titulo: 'Você Alternativo',
                                      emoji: '✨',
                                      cor: const Color(0xFF7C5CFC),
                                      bandeiraUrl: widget.vida.bandeiraUrl,
                                      paisCode: widget.vida.paisCode,
                                      items: [
                                        _ItemInfo(
                                          icone: '🌍',
                                          label: 'País',
                                          valor: widget.vida.paisNome,
                                        ),
                                        _ItemInfo(
                                          icone: '🗓️',
                                          label: 'Nascimento',
                                          valor: dataNasc,
                                        ),
                                        _ItemInfo(
                                          icone: '👥',
                                          label: 'População',
                                          valor: _formatarPopulacao(
                                            widget.vida.populacao,
                                          ),
                                        ),
                                        _ItemInfo(
                                          icone: '📍',
                                          label: 'Capital',
                                          valor: widget.vida.capital ?? '—',
                                        ),
                                        _ItemInfo(
                                          icone: '🗣️',
                                          label: 'Idioma',
                                          valor: widget.vida.idioma ?? '—',
                                        ),
                                        _ItemInfo(
                                          icone: '💰',
                                          label: 'Moeda',
                                          valor: widget.vida.moeda ?? '—',
                                        ),
                                        _ItemInfo(
                                          icone: '❤️',
                                          label: 'Expectativa',
                                          valor:
                                              widget.vida.expectativaVida !=
                                                  null
                                              ? '${widget.vida.expectativaVida!.toStringAsFixed(1)} anos'
                                              : '—',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // ── Card de clima ────────────────────────
                              if (clima.isNotEmpty &&
                                  clima['descricao'] !=
                                      'Dados climáticos não disponíveis') ...[
                                _ClimaCard(clima: clima, data: dataNasc),
                                const SizedBox(height: 20),
                              ],

                              // ── Card IA resumo ────────────────────────
                              if (clima.containsKey('ia_resumo')) ...[
                                _IaResumoCard(
                                  resumo: clima['ia_resumo'] as String,
                                ),
                                const SizedBox(height: 20),
                              ],

                              // ── Botões de ação ───────────────────────
                              _BotoesAcao(
                                salvo: _salvo,
                                salvando: _salvando,
                                onSalvar: _salvar,
                                onSortearNovamente: () => context.go(
                                  '/sorteio',
                                  extra: widget.usuario,
                                ),
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FraseDestaque extends StatelessWidget {
  final String texto;
  final ({Color cor, IconData icone, String label}) comparacao;

  const _FraseDestaque({required this.texto, required this.comparacao});

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
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(comparacao.icone, color: comparacao.cor, size: 14),
                const SizedBox(width: 4),
                Text(
                  comparacao.label,
                  style: TextStyle(
                    color: comparacao.cor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemInfo {
  final String icone;
  final String label;
  final String valor;
  const _ItemInfo({
    required this.icone,
    required this.label,
    required this.valor,
  });
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
    return code
        .toUpperCase()
        .codeUnits
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
          // Cabeçalho da coluna
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  style: TextStyle(
                    color: cor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  )
                else
                  Text(
                    _bandeiraPorCodigo(paisCode),
                    style: const TextStyle(fontSize: 32),
                  ),
              ],
            ),
          ),
          // Itens de dados
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.icone} ${item.label}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.valor,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  String _iconeClima(String descricao) {
    final d = descricao.toLowerCase();
    if (d.contains('chuva') || d.contains('chuvoso')) return '🌧️';
    if (d.contains('neve') || d.contains('nevando')) return '❄️';
    if (d.contains('nublado') || d.contains('nuvem')) return '☁️';
    if (d.contains('sol') || d.contains('ensolarado')) return '☀️';
    if (d.contains('tempestade') || d.contains('trovoada')) return '⛈️';
    return '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    final temp = clima['temperatura_max'];
    final desc = clima['descricao'] as String? ?? 'Clima não disponível';
    final icone = _iconeClima(desc);

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
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: Colors.white54,
                size: 15,
              ),
              const SizedBox(width: 6),
              const Text(
                'Clima no seu dia de nascimento',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(icone, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temp != null
                        ? '${(temp as num).toStringAsFixed(0)}°C'
                        : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card de análise da IA extraído como widget dedicado
class _IaResumoCard extends StatelessWidget {
  final String resumo;
  const _IaResumoCard({required this.resumo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C5CFC).withOpacity(0.2),
            const Color(0xFF4A90D9).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C5CFC).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'Análise da IA',
                style: TextStyle(
                  color: Color(0xFF9E86FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            resumo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton.icon(
              onPressed: salvo ? null : onSalvar,
              icon: salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      salvo ? Icons.check_circle : Icons.bookmark_add_outlined,
                    ),
              label: Text(salvo ? 'Vida salva!' : 'Salvar esta vida'),
              style: ElevatedButton.styleFrom(
                backgroundColor: salvo
                    ? Colors.green[700]
                    : const Color(0xFF7C5CFC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: Colors.green[700],
                disabledForegroundColor: Colors.white,
              ),
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
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
