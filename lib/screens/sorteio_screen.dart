import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/models/usuario_model.dart';
import '../providers/vida_provider.dart';

class SorteioScreen extends StatefulWidget {
  final UsuarioModel usuario;
  const SorteioScreen({super.key, required this.usuario});

  @override
  State<SorteioScreen> createState() => _SorteioScreenState();
}

class _SorteioScreenState extends State<SorteioScreen>
    with TickerProviderStateMixin {
  // Animação do globo
  late AnimationController _globoController;
  late Animation<double> _globoRotacao;
  late Animation<double> _globoEscala;

  // Fade-in do resultado
  late AnimationController _revelarController;
  late Animation<double> _revelarFade;
  late Animation<Offset> _revelarSlide;

  // Pulso no globo enquanto carrega
  late AnimationController _pulsoController;
  late Animation<double> _pulso;

  bool _sorteioIniciado = false;

  @override
  void initState() {
    super.initState();

    _globoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _globoRotacao = Tween<double>(
      begin: 0,
      end: 2 * math.pi * 3, // 3 voltas completas
    ).animate(CurvedAnimation(
      parent: _globoController,
      curve: Curves.easeInOut,
    ));
    _globoEscala = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(_globoController);

    _pulsoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulso = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _revelarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revelarFade =
        CurvedAnimation(parent: _revelarController, curve: Curves.easeOut);
    _revelarSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _revelarController, curve: Curves.easeOut));

    // Inicia o sorteio automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarSorteio());
  }

  @override
  void dispose() {
    _globoController.dispose();
    _pulsoController.dispose();
    _revelarController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSorteio() async {
    if (_sorteioIniciado) return;
    setState(() => _sorteioIniciado = true);

    final provider = context.read<VidaProvider>();

    // Inicia animação do globo em paralelo com a requisição
    _globoController.forward();

    await provider.sortearNovaVida(
      widget.usuario.id!,
      widget.usuario.dataNascimento,
    );

    // Garante que a animação do globo termina antes de revelar (mín. 3s)
    await _globoController.forward(from: _globoController.value);

    if (!mounted) return;

    if (provider.error != null) return; // Erro tratado no build

    _pulsoController.stop();
    await _revelarController.forward();
  }

  void _sortearNovamente() {
    _revelarController.reset();
    _globoController.reset();
    setState(() => _sorteioIniciado = false);
    _iniciarSorteio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0B1E), Color(0xFF1A1040), Color(0xFF0D1B3E)],
          ),
        ),
        child: SafeArea(
          child: Consumer<VidaProvider>(
            builder: (_, prov, __) {
              return Column(
                children: [
                  // AppBar simples
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white70),
                          onPressed: () => context.pop(),
                        ),
                        const Text(
                          'Sorteando sua vida...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _buildConteudo(prov),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo(VidaProvider prov) {
    // Estado de erro
    if (prov.error != null) {
      return _ErroWidget(
        mensagem: prov.error!,
        onRetry: () {
          prov.clearError();
          _sortearNovamente();
        },
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // GLOBO animado
        _GloboAnimado(
          rotacaoAnim: _globoRotacao,
          escalaAnim: _globoEscala,
          pulsoAnim: _pulso,
          mostrandoResultado: prov.currentVida != null,
          globoController: _globoController,
        ),

        const SizedBox(height: 40),

        // Resultado com fade-in
        if (prov.currentVida != null)
          FadeTransition(
            opacity: _revelarFade,
            child: SlideTransition(
              position: _revelarSlide,
              child: _ResultadoWidget(
                vida: prov.currentVida!,
                onVerComparativo: () =>
                    context.push('/comparativo', extra: {
                      'usuario': widget.usuario,
                      'vida': prov.currentVida,
                    }),
                onSortearNovamente: _sortearNovamente,
              ),
            ),
          )
        else
          _TextoSuspense(controller: _globoController),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _GloboAnimado extends StatelessWidget {
  final Animation<double> rotacaoAnim;
  final Animation<double> escalaAnim;
  final Animation<double> pulsoAnim;
  final bool mostrandoResultado;
  final AnimationController globoController;

  const _GloboAnimado({
    required this.rotacaoAnim,
    required this.escalaAnim,
    required this.pulsoAnim,
    required this.mostrandoResultado,
    required this.globoController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rotacaoAnim, escalaAnim, pulsoAnim]),
      builder: (_, __) {
        final escala = globoController.isAnimating
            ? escalaAnim.value
            : (mostrandoResultado ? 1.0 : pulsoAnim.value);

        return Transform.scale(
          scale: escala,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo / glow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C5CFC).withOpacity(
                          globoController.isAnimating ? 0.6 : 0.3),
                      blurRadius: globoController.isAnimating ? 60 : 30,
                      spreadRadius: globoController.isAnimating ? 20 : 10,
                    ),
                  ],
                ),
              ),
              // Globo com rotação
              Transform.rotate(
                angle: globoController.isAnimating ? rotacaoAnim.value : 0,
                child: const Text(
                  '🌍',
                  style: TextStyle(fontSize: 110),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TextoSuspense extends StatelessWidget {
  final AnimationController controller;

  const _TextoSuspense({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final progresso = controller.value;
        String texto = 'Girando o globo...';
        if (progresso > 0.6) texto = 'Quase lá...';
        if (progresso > 0.85) texto = 'Revelando seu destino...';

        return Column(
          children: [
            Text(
              texto,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                value: progresso,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7C5CFC)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultadoWidget extends StatelessWidget {
  final dynamic vida; // VidaAlternativaModel
  final VoidCallback onVerComparativo;
  final VoidCallback onSortearNovamente;

  const _ResultadoWidget({
    required this.vida,
    required this.onVerComparativo,
    required this.onSortearNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Bandeira
          if (vida.bandeiraUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: vida.bandeiraUrl!,
                width: 120,
                height: 75,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                const Text('🏳️', style: TextStyle(fontSize: 60)),
              ),
            )
          else
            const Text('🏳️', style: TextStyle(fontSize: 60)),

          const SizedBox(height: 20),

          const Text(
            'Você nasceria em...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            vida.paisNome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          if (vida.capital != null) ...[
            const SizedBox(height: 4),
            Text(
              '📍 ${vida.capital}',
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],

          const SizedBox(height: 32),

          // Botão: Ver comparativo
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onVerComparativo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 6,
              ),
              child: const Text(
                'Ver minha vida alternativa',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botão: Sortear outro
          TextButton.icon(
            onPressed: onSortearNovamente,
            icon: const Icon(Icons.refresh, color: Colors.white54),
            label: const Text(
              'Sortear outro país',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroWidget extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;

  const _ErroWidget({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 64),
          const SizedBox(height: 20),
          Text(
            mensagem,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C5CFC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}