import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasci_lugar_errado/screens/comparativo_screan.dart';
import 'package:provider/provider.dart';

import 'data/models/usuario_model.dart';
import 'data/models/vida_alternativa_model.dart';
import 'providers/usuario_provider.dart';
import 'providers/vida_provider.dart';
import 'screens/entrada_screen.dart';
import 'screens/sorteio_screen.dart';
import 'screens/historico_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const NasceuLugarErradoApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Shell: telas com bottom nav (Entrada e Histórico)
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const EntradaScreen()),
        GoRoute(
          path: '/historico',
          builder: (_, state) {
            // O usuario vem do UsuarioProvider — não precisa de extra
            return const HistoricoScreen();
          },
        ),
      ],
    ),

    // Rotas de fluxo: SEM bottom nav
    GoRoute(
      path: '/sorteio',
      builder: (_, state) {
        final usuario = state.extra as UsuarioModel;
        return SorteioScreen(usuario: usuario);
      },
    ),
    GoRoute(
      path: '/comparativo',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ComparativoScreen(
          usuario: extra['usuario'] as UsuarioModel,
          vida: extra['vida'] as VidaAlternativaModel,
        );
      },
    ),
  ],
);

// ── App ───────────────────────────────────────────────────────────────────────

class NasceuLugarErradoApp extends StatelessWidget {
  const NasceuLugarErradoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UsuarioProvider()..carregarUltimoUsuario(),
        ),
        ChangeNotifierProvider(create: (_) => VidaProvider()),
      ],
      child: MaterialApp.router(
        title: 'Você Nasceu no Lugar Errado?',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0B1E),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7C5CFC),
            secondary: Color(0xFF4A90D9),
            surface: Color(0xFF1E1B3A),
          ),
          useMaterial3: true,
        ),
      ),
    );
  }
}

// ── Shell com Bottom Navigation Bar ──────────────────────────────────────────

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _indexAtual(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/historico')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexAtual(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12102A),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icone: Icons.explore_rounded,
                  iconeSelecionado: Icons.explore,
                  label: 'Descobrir',
                  selecionado: index == 0,
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icone: Icons.history_rounded,
                  iconeSelecionado: Icons.history,
                  label: 'Histórico',
                  selecionado: index == 1,
                  onTap: () => context.go('/historico'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icone;
  final IconData iconeSelecionado;
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const _NavItem({
    required this.icone,
    required this.iconeSelecionado,
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const cor = Color(0xFF7C5CFC);
    final corIcone = selecionado ? cor : Colors.white38;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? cor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selecionado ? iconeSelecionado : icone,
              color: corIcone,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: corIcone,
                fontSize: 11,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
