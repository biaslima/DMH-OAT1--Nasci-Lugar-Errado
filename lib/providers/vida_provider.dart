import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/dao/vida_dao.dart';
import '../data/models/vida_alternativa_model.dart';
import '../services/countries_service.dart';
import '../services/weather_service.dart';
import '../services/groq_service.dart';

final _groqService = GroqService();

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

  //Getters
  VidaAlternativaModel? get currentVida => _currentVida;
  List<VidaAlternativaModel> get listaVidas => _listaVidas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrdemHistorico get ordem => _ordem;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sortear
  Future<void> sortearNovaVida(
    int usuarioId,
    String dataNascimento,
    String paisOrigemNome,
  ) async {
    _isLoading = true;
    _error = null;
    _currentVida = null;
    notifyListeners();

    try {
      final pais = await _countriesService.getRandomCountry();
      final nomeDestino =
          (pais['name'] as Map?)?['common'] as String? ?? 'Desconhecido';

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
          climaData = {'descricao': 'Dados climáticos não disponíveis'};
        }
      }

      try {
        final iaResumo = await _groqService.gerarResumoComparativo(
          paisOrigemNome,
          nomeDestino,
        );
        climaData['ia_resumo'] = iaResumo;
      } catch (_) {
        climaData['ia_resumo'] = "Análise indisponível.";
      }

      _currentVida = _montarVida(
        pais: pais,
        usuarioId: usuarioId,
        climaData: climaData,
      );
      await salvarVidaAtual();
    } catch (e) {
      _error = _mensagemAmigavel(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Salvar
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

  // Histórico
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

  //Helpers
  VidaAlternativaModel _montarVida({
    required Map<String, dynamic> pais,
    required int usuarioId,
    required Map<String, dynamic> climaData,
  }) {
    final nome = (pais['name'] as Map?)?['common'] as String? ?? 'Desconhecido';
    final capital = (pais['capital'] as List?)?.isNotEmpty == true
        ? pais['capital'][0] as String
        : null;
    final idioma = (pais['languages'] as Map?)?.values.first?.toString();
    final populacao = pais['population'] as int?;

    String? moeda;
    final moedaMap = pais['currencies'] as Map?;
    if (moedaMap != null && moedaMap.isNotEmpty) {
      final key = moedaMap.keys.first as String;
      final nomeMoeda = (moedaMap[key] as Map?)?['name'] as String? ?? key;
      moeda = '$nomeMoeda ($key)';
    }

    return VidaAlternativaModel(
      usuarioId: usuarioId,
      paisCode: pais['cca2'] as String? ?? '??',
      paisNome: nome,
      capital: capital,
      idioma: idioma,
      populacao: populacao,
      expectativaVida: _expectativaReal(
        pais['cca2'] as String? ?? '',
        pais['region'] as String? ?? '',
      ),
      moeda: moeda,
      climaNascimento: jsonEncode(climaData),
      bandeiraUrl: (pais['flags'] as Map?)?['png'] as String?,
    );
  }

  double _expectativaReal(String paisCode, String regiao) {
    final mapExpectativa = {
      'BR': 75.3, // Brasil
      'US': 77.2, // Estados Unidos
      'JP': 84.6, // Japão
      'CN': 78.2, // China
      'NG': 55.0, // Nigéria
      'CA': 82.6, // Canadá
      'AU': 83.4, // Austrália
      'DE': 81.0, // Alemanha
      'FR': 82.3, // França
      'IN': 67.2, // Índia
      'AR': 76.6, // Argentina
      'PT': 81.5, // Portugal
      'IT': 82.8, // Itália
      'ZA': 64.1, // África do Sul
      'RU': 71.3, // Rússia
      'MX': 75.0, // México
      'ES': 83.2, // Espanha
      'KR': 83.5, // Coreia do Sul
      'UK': 81.2, // Reino Unido
      'SE': 83.1, // Suécia
      'NO': 83.2, // Noruega
      'FI': 81.9, // Finlândia
      'DK': 81.6, // Dinamarca
      'NL': 81.7, // Holanda
      'BE': 81.9, // Bélgica
      'CH': 83.8, // Suíça
      'AT': 81.5, // Áustria
      'IE': 82.4, // Irlanda
      'NZ': 82.8, // Nova Zelândia
      'SG': 84.3, // Singapura
      'TH': 78.7, // Tailândia
      'MY': 75.6, // Malásia
      'ID': 71.7, // Indonésia
      'PH': 71.4, // Filipinas
      'EG': 70.2, // Egito
      'TR': 77.7, // Turquia
      'SA': 75.1, // Arábia Saudita
      'AE': 78.1, // Emirados Árabes
      'IL': 83.0, // Israel
      'CL': 81.0, // Chile
      'CO': 77.3, // Colômbia
      'PE': 76.5, // Peru
      'VE': 72.1, // Venezuela
      'PL': 77.5, // Polônia
      'CZ': 79.1, // República Tcheca
      'HU': 76.2, // Hungria
      'GR': 81.1, // Grécia
      'UA': 71.0, // Ucrânia
      'PK': 66.1, // Paquistão
      'BD': 72.4, // Bangladesh
      'KE': 66.7, // Quênia
      'ET': 66.6, // Etiópia
      'GH': 64.5, // Gana
    };

    if (mapExpectativa.containsKey(paisCode.toUpperCase())) {
      return mapExpectativa[paisCode.toUpperCase()]!;
    }

    switch (regiao) {
      case 'Europe':
        return 78.5;
      case 'Americas':
        return 74.2;
      case 'Asia':
        return 73.8;
      case 'Oceania':
        return 77.1;
      case 'Africa':
        return 62.7;
      default:
        return 70.0;
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
