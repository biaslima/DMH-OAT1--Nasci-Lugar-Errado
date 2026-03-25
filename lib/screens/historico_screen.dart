import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/usuario_model.dart';
import '../data/models/vida_alternativa_model.dart';
import '../providers/usuario_provider.dart';
import '../providers/vida_provider.dart';
import '../widgets/app_error_widget.dart';
import '../widgets/vida_card.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usuario = context.read<UsuarioProvider>().usuario;
      if (usuario != null) {
        context.read<VidaProvider>().carregarHistorico(usuario.id!);
      }
    });
  }

  UsuarioModel? get _usuario =>
      context.read<UsuarioProvider>().usuario;

  Future<bool?> _confirmarDelecao(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B3A),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover vida?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta vida alternativa será removida do histórico.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red[700]),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0B1E), Color(0xFF1A1040), Color(0xFF0D1B3E)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Minhas Vidas Alternativas',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          actions: [
            Consumer<VidaProvider>(
              builder: (context, provider, _) {
                final usuario = _usuario;
                if (usuario == null) return const SizedBox.shrink();
                return PopupMenuButton<OrdemHistorico>(
                  tooltip: 'Ordenar',
                  icon: const Icon(Icons.sort_rounded,
                      color: Color(0xFF7C5CFC)),
                  color: const Color(0xFF1E1B3A),
                  onSelected: (ordem) =>
                      provider.alterarOrdem(ordem, usuario.id!),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: OrdemHistorico.maisRecente,
                      child: Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 18, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Mais recente',
                            style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: OrdemHistorico.maiorLongevidade,
                      child: Row(children: [
                        Icon(Icons.favorite_rounded,
                            size: 18, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Maior longevidade',
                            style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer2<UsuarioProvider, VidaProvider>(
          builder: (context, usuarioProv, vidaProv, _) {
            // Sem usuário ainda (primeiro acesso)
            if (usuarioProv.usuario == null) {
              return const _SemUsuario();
            }

            if (vidaProv.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF7C5CFC)),
              );
            }

            if (vidaProv.error != null) {
              return AppErrorWidget(
                mensagem: vidaProv.error!,
                onRetry: () => vidaProv
                    .carregarHistorico(usuarioProv.usuario!.id!),
              );
            }

            if (vidaProv.listaVidas.isEmpty) {
              return const _EmptyState();
            }

            return RefreshIndicator(
              color: const Color(0xFF7C5CFC),
              onRefresh: () =>
                  vidaProv.carregarHistorico(usuarioProv.usuario!.id!),
              child: ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: vidaProv.listaVidas.length,
                itemBuilder: (context, index) {
                  final vida = vidaProv.listaVidas[index];
                  return _VidaItemAnimado(
                    key: ValueKey(vida.id),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey('d_${vida.id}'),
                        direction: DismissDirection.endToStart,
                        background: _DismissBackground(),
                        confirmDismiss: (_) =>
                            _confirmarDelecao(context),
                        onDismissed: (_) {
                          vidaProv.deletarVida(
                              vida.id!, usuarioProv.usuario!.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${vida.paisNome} removida do histórico'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor:
                              const Color(0xFF1E1B3A),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10)),
                            ),
                          );
                        },
                        child: VidaCard(
                          vida: vida,
                          onFavoritaTap: () => vidaProv.toggleFavorita(
                            vida.id!,
                            vida.favorita == 0,
                            usuarioProv.usuario!.id!,
                          ),
                          onTap: () =>
                              _mostrarDetalhes(context, vida),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _mostrarDetalhes(BuildContext context, VidaAlternativaModel vida) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1B3A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              vida.paisNome,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Detalhes em grid
            _DetalheGrid(vida: vida),
            const SizedBox(height: 16),
            // Favoritar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  final usuario = _usuario;
                  if (usuario != null) {
                    context.read<VidaProvider>().toggleFavorita(
                      vida.id!,
                      vida.favorita == 0,
                      usuario.id!,
                    );
                  }
                },
                icon: Icon(
                  vida.favorita == 1
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFFFD700),
                ),
                label: Text(
                  vida.favorita == 1
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  style: const TextStyle(color: Colors.white70),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SemUsuario extends StatelessWidget {
  const _SemUsuario();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Comece pela aba Descobrir!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha seus dados e descubra onde você deveria ter nascido.',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C5CFC).withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: const Text('📭', style: TextStyle(fontSize: 52)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma vida salva ainda',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Sorteie seu destino alternativo e salve as vidas que mais te chamarem atenção.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[700]!.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text('Excluir',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DetalheGrid extends StatelessWidget {
  final VidaAlternativaModel vida;
  const _DetalheGrid({required this.vida});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (vida.capital != null) _Detalhe('📍 Capital', vida.capital!),
      if (vida.idioma != null) _Detalhe('🗣️ Idioma', vida.idioma!),
      if (vida.moeda != null) _Detalhe('💰 Moeda', vida.moeda!),
      if (vida.expectativaVida != null)
        _Detalhe('❤️ Expectativa',
            '${vida.expectativaVida!.toStringAsFixed(1)} anos'),
      if (vida.populacao != null)
        _Detalhe('👥 População', _formatPop(vida.populacao!)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((d) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 2),
            Text(d.valor,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ))
          .toList(),
    );
  }

  String _formatPop(int pop) {
    if (pop >= 1e9) return '${(pop / 1e9).toStringAsFixed(1)}B';
    if (pop >= 1e6) return '${(pop / 1e6).toStringAsFixed(1)}M';
    if (pop >= 1000) return '${(pop / 1000).toStringAsFixed(0)}k';
    return pop.toString();
  }
}

class _Detalhe {
  final String label;
  final String valor;
  const _Detalhe(this.label, this.valor);
}

class _VidaItemAnimado extends StatefulWidget {
  final int index;
  final Widget child;
  const _VidaItemAnimado(
      {super.key, required this.index, required this.child});

  @override
  State<_VidaItemAnimado> createState() => _VidaItemAnimadoState();
}

class _VidaItemAnimadoState extends State<_VidaItemAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child));
  }
}