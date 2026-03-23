import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/dao/vida_dao.dart';
import '../data/models/vida_alternativa_model.dart';
import '../services/countries_service.dart';
import '../services/weather_service.dart';

enum OrdemHistorico { maisRecente, maiorLongevidade }

class VidaProvider with ChangeNotifier {
  final _vidaDao = VidaDao();
  final _countriesService = CountriesService();
  final _weatherService = WeatherService();

  VidaAlternativaModel? _currentVida;
  List<VidaAlternativaModel> _listaVidas = [];
  bool _isLoading = false;
  String? _error;
  OrdemHistorico _ordem = OrdemHistorico.maisRecente;

  // ── Getters ──────────────────────────────────────────────────────────────
  VidaAlternativaModel? get currentVida => _currentVida;
  List<VidaAlternativaModel> get listaVidas => _listaVidas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrdemHistorico get ordem => _ordem;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Sortear ───────────────────────────────────────────────────────────────
  /// Sorteia um país aleatório, busca o clima histórico e monta um
  /// [VidaAlternativaModel] sem persistir ainda (o usuário decide depois).
  Future<void> sortearNovaVida(int usuarioId, String dataNascimento) async {
    _isLoading = true;
    _error = null;
    _currentVida = null;
    notifyListeners();

    try {
      // 1. País aleatório via REST Countries
      final pais = await _countriesService.getRandomCountry();

      // 2. Extrai lat/lon para buscar o clima
      final latlng = pais['latlng'] as List?;
      Map<String, dynamic> climaData = {};
      if (latlng != null && latlng.length >= 2) {
        try {
          climaData = await _weatherService.getHistoricalWeather(
            lat: (latlng[0] as num).toDouble(),
            lon: (latlng[1] as num).toDouble(),
            date: dataNascimento,
          );
        } catch (_) {
          // Fallback silencioso — nem toda data/localização tem dados
          climaData = {'descricao': 'Dados climáticos não disponíveis'};
        }
      }

      // 3. Monta o modelo (ainda não salvo no banco)
      _currentVida = _montarVida(
        pais: pais,
        usuarioId: usuarioId,
        climaData: climaData,
      );
    } catch (e) {
      _error = _mensagemAmigavel(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Salvar ────────────────────────────────────────────────────────────────
  /// Persiste a vida atual no SQLite e atualiza o id gerado.
  Future<bool> salvarVidaAtual() async {
    if (_currentVida == null) return false;
    try {
      final id = await _vidaDao.insert(_currentVida!);
      _currentVida = _currentVida!.copyWith(id: id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao salvar vida: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Histórico ─────────────────────────────────────────────────────────────
  Future<void> carregarHistorico(int usuarioId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _listaVidas = _ordem == OrdemHistorico.maisRecente
          ? await _vidaDao.getAll(usuarioId)
          : await _vidaDao.getAllByLongevidade(usuarioId);
    } catch (e) {
      _error = 'Erro ao carregar histórico: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletarVida(int id, int usuarioId) async {
    try {
      await _vidaDao.deleteById(id);
      await carregarHistorico(usuarioId);
    } catch (e) {
      _error = 'Erro ao deletar: $e';
      notifyListeners();
    }
  }

  Future<void> toggleFavorita(int id, bool favorita, int usuarioId) async {
    try {
      await _vidaDao.toggleFavorita(id, favorita);
      await carregarHistorico(usuarioId);
    } catch (e) {
      _error = 'Erro ao atualizar favorita: $e';
      notifyListeners();
    }
  }

  void alterarOrdem(OrdemHistorico novaOrdem, int usuarioId) {
    if (_ordem == novaOrdem) return;
    _ordem = novaOrdem;
    carregarHistorico(usuarioId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  VidaAlternativaModel _montarVida({
    required Map<String, dynamic> pais,
    required int usuarioId,
    required Map<String, dynamic> climaData,
  }) {
    final nome =
        (pais['name'] as Map?)?['common'] as String? ?? 'Desconhecido';
    final capital = (pais['capital'] as List?)?.isNotEmpty == true
        ? pais['capital'][0] as String
        : null;
    final idioma =
    (pais['languages'] as Map?)?.values.first?.toString();
    final populacao = pais['population'] as int?;

    String? moeda;
    final moedaMap = pais['currencies'] as Map?;
    if (moedaMap != null && moedaMap.isNotEmpty) {
      final key = moedaMap.keys.first as String;
      final nomeMoeda =
          (moedaMap[key] as Map?)?['name'] as String? ?? key;
      moeda = '$nomeMoeda ($key)';
    }

    return VidaAlternativaModel(
      usuarioId: usuarioId,
      paisCode: pais['cca2'] as String? ?? '??',
      paisNome: nome,
      capital: capital,
      idioma: idioma,
      populacao: populacao,
      expectativaVida:
      _expectativaPorRegiao(pais['region'] as String? ?? ''),
      moeda: moeda,
      climaNascimento: jsonEncode(climaData),
      bandeiraUrl: (pais['flags'] as Map?)?['png'] as String?,
    );
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

  String _mensagemAmigavel(String erro) {
    if (erro.contains('SocketException') || erro.contains('connection')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    if (erro.contains('timeout')) {
      return 'A requisição demorou demais. Tente novamente.';
    }
    return 'Erro ao sortear país. Tente novamente.';
  }
}