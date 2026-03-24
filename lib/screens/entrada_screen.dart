import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';
import '../services/countries_service.dart';

class PaisItem {
  final String code;
  final String nome;

  const PaisItem({required this.code, required this.nome});

  factory PaisItem.fromApi(Map<String, dynamic> json) => PaisItem(
    code: json['cca2'] as String? ?? '??',
    nome: (json['name'] as Map?)?['common'] as String? ?? '?',
  );

  String get bandeira => code.toUpperCase().codeUnits
      .map((c) => String.fromCharCode(c + 127397))
      .join();
}

class EntradaScreen extends StatefulWidget {
  const EntradaScreen({super.key});

  @override
  State<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends State<EntradaScreen>
    with TickerProviderStateMixin {
  DateTime? _dataNascimento;
  PaisItem? _paisSelecionado;
  List<PaisItem> _paises = [];
  List<PaisItem> _paisesFiltrados = [];
  bool _loadingPaises = true;
  bool _formSubmetido = false;

  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPaises();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarPaises() async {
    try {
      final lista = await CountriesService().getAllCountries();
      final paises = lista
          .map((e) => PaisItem.fromApi(e))
          .toList()
        ..sort((a, b) => a.nome.compareTo(b.nome)); // alfabética
      setState(() {
        _paises = paises;
        _paisesFiltrados = List.from(paises);
        _loadingPaises = false;
      });
    } catch (_) {
      setState(() => _loadingPaises = false);
    }
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: hoje,
      helpText: 'Quando você nasceu?',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C5CFC),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1B3A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dataNascimento = picked);
    }
  }

  void _filtrarPaises(String query) {
    setState(() {
      _paisesFiltrados = _paises
          .where((p) =>
      p.nome.toLowerCase().contains(query.toLowerCase()) ||
          p.code.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _abrirDropdownPaises() async {
    _searchController.clear();
    setState(() => _paisesFiltrados = List.from(_paises));

    final result = await showModalBottomSheet<PaisItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1B3A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Seu país de origem',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar país...',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixIcon:
                      const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) {
                      setModalState(() {
                        _paisesFiltrados = _paises
                            .where((p) =>
                        p.nome
                            .toLowerCase()
                            .contains(v.toLowerCase()) ||
                            p.code.toLowerCase().contains(v.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _paisesFiltrados.length,
                    itemBuilder: (_, i) {
                      final pais = _paisesFiltrados[i];
                      final selecionado =
                          _paisSelecionado?.code == pais.code;
                      return ListTile(
                        leading: Text(
                          pais.bandeira,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          pais.nome,
                          style: TextStyle(
                            color: selecionado
                                ? const Color(0xFF7C5CFC)
                                : Colors.white,
                            fontWeight: selecionado
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: selecionado
                            ? const Icon(Icons.check_circle,
                            color: Color(0xFF7C5CFC))
                            : null,
                        onTap: () => Navigator.pop(ctx, pais),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result != null) {
      setState(() => _paisSelecionado = result);
    }
  }

  bool get _formularioValido =>
      _dataNascimento != null && _paisSelecionado != null;

  Future<void> _descobrir() async {
    setState(() => _formSubmetido = true);
    if (!_formularioValido) return;

    await _buttonController.forward();
    await _buttonController.reverse();

    final provider = context.read<UsuarioProvider>();
    final usuario = await provider.salvarUsuario(
      dataNascimento:
      DateFormat('yyyy-MM-dd').format(_dataNascimento!),
      paisOrigemCode: _paisSelecionado!.code,
      paisOrigemNome: _paisSelecionado!.nome,
    );

    if (!mounted) return;
    if (usuario != null) {
      context.push('/sorteio', extra: usuario);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erro ao salvar dados.'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0B1E), Color(0xFF1A1040), Color(0xFF0D1B3E)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  const Text(
                    '🌍',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Você nasceu no lugar errado?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descubra como seria sua vida em outro país.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Campo: Data de nascimento
                  _Label('Quando você nasceu?'),
                  const SizedBox(height: 8),
                  _CampoToque(
                    onTap: _selecionarData,
                    erro: _formSubmetido && _dataNascimento == null
                        ? 'Informe sua data de nascimento'
                        : null,
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined,
                            color: Color(0xFF7C5CFC), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _dataNascimento != null
                              ? DateFormat('dd/MM/yyyy')
                              .format(_dataNascimento!)
                              : 'Selecionar data',
                          style: TextStyle(
                            color: _dataNascimento != null
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: Colors.white38),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Campo: País de origem
                  _Label('Qual é o seu país de origem?'),
                  const SizedBox(height: 8),
                  _loadingPaises
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF7C5CFC)))
                      : _CampoToque(
                    onTap: _abrirDropdownPaises,
                    erro: _formSubmetido && _paisSelecionado == null
                        ? 'Selecione seu país de origem'
                        : null,
                    child: Row(
                      children: [
                        if (_paisSelecionado != null) ...[
                          Text(
                            _paisSelecionado!.bandeira,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _paisSelecionado!.nome,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.public_outlined,
                              color: Color(0xFF7C5CFC), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Selecionar país',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 16),
                          ),
                          const Spacer(),
                        ],
                        const Icon(Icons.chevron_right,
                            color: Colors.white38),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Buscas recentes do SQLite
                  _HistoricoRecente(),

                  const SizedBox(height: 40),

                  // Botão principal
                  ScaleTransition(
                    scale: _buttonScale,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _descobrir,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C5CFC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor:
                          const Color(0xFF7C5CFC).withOpacity(0.5),
                        ),
                        child: Consumer<UsuarioProvider>(
                          builder: (_, prov, __) => prov.isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Descobrir minha outra vida',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets internos ───────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CampoToque extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final String? erro;

  const _CampoToque({
    required this.onTap,
    required this.child,
    this.erro,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: erro != null
                    ? Colors.red.withOpacity(0.7)
                    : Colors.white.withOpacity(0.12),
              ),
            ),
            child: child,
          ),
        ),
        if (erro != null) ...[
          const SizedBox(height: 4),
          Text(
            erro!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _HistoricoRecente extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UsuarioProvider>(
      builder: (_, prov, __) {
        if (prov.usuario == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.history, color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Última busca: ${prov.usuario!.paisOrigemNome}',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}