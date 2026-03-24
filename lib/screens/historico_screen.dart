import 'package:flutter/material.dart';
import 'package:nasci_lugar_errado/data/models/usuario_model.dart';
import 'package:provider/provider.dart';
import 'package:nasci_lugar_errado/providers/vida_provider.dart';
import 'package:nasci_lugar_errado/widgets/vida_card.dart';
import 'package:nasci_lugar_errado/widgets/app_error_widget.dart';

class HistoricoScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const HistoricoScreen({super.key, required this.usuario});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VidaProvider>().carregarHistorico(widget.usuario.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Minhas Vidas Alternativas'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<VidaProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<OrdemHistorico>(
                tooltip: 'Ordenar',
                icon: Icon(Icons.sort_rounded, color: colorScheme.primary),
                onSelected: (ordem) =>
                    provider.alterarOrdem(ordem, widget.usuario.id!),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: OrdemHistorico.maisRecente,
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Mais recente'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: OrdemHistorico.maiorLongevidade,
                    child: Row(
                      children: [
                        Icon(Icons.favorite_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Maior longevidade'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<VidaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return AppErrorWidget(
              mensagem: provider.error!,
              onRetry: () => provider.carregarHistorico(widget.usuario.id!),
            );
          }

          if (provider.listaVidas.isEmpty) {
            return _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.carregarHistorico(widget.usuario.id!),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: provider.listaVidas.length,
              itemBuilder: (context, index) {
                final vida = provider.listaVidas[index];

                return Dismissible(
                  key: ValueKey(vida.id),
                  direction: DismissDirection.endToStart,
                  background: _DismissBackground(),
                  confirmDismiss: (_) => _confirmarDelecao(context),
                  onDismissed: (_) {
                    provider.deletarVida(vida.id!, widget.usuario.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${vida.paisNome} removida do histórico'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: VidaCard(
                    vida: vida,
                    onFavoritaTap: () => provider.toggleFavorita(
                      vida.id!,
                      vida.favorita == 0,
                      widget.usuario.id!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmarDelecao(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover vida?'),
        content: const Text('Esta vida alternativa será removida do histórico.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(
        Icons.delete_rounded,
        color: Theme.of(context).colorScheme.onErrorContainer,
        size: 28,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🌍',
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma vida salva ainda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sorteie seu destino alternativo e salve as vidas que mais te chamaram atenção.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}