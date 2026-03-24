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


void main() {
  runApp(const NasceuLugarErradoApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const EntradaScreen(),
    ),
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

    GoRoute(
      path: '/historico',
      builder: (_, state) {
        final usuario = state.extra as UsuarioModel;
        return HistoricoScreen(usuario: usuario);
      },
    ),
  ],
);

class NasceuLugarErradoApp extends StatelessWidget {
  const NasceuLugarErradoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => UsuarioProvider()..carregarUltimoUsuario()),
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