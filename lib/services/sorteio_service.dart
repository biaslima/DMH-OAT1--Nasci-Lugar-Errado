import 'dart:convert';
import '../data/models/vida_alternativa_model.dart';
import 'countries_service.dart';
import 'weather_service.dart';

class SorteioService {
  final _countriesService = CountriesService();
  final _weatherService = WeatherService();

  /// Sorteia um país aleatório, busca o clima histórico e monta um [VidaAlternativaModel]
  Future<VidaAlternativaModel> sortear({
    required String dataNascimento,
    required int usuarioId,
  }) async {
    // 1. Busca um país aleatório
    final pais = await _countriesService.getRandomCountry();

    // 2. Extrai lat/lon para buscar o clima
    final lat = pais['latlng']?[0] as double?;
    final lon = pais['latlng']?[1] as double?;

    Map<String, dynamic> climaData = {};
    if (lat != null && lon != null) {
      try {
        climaData = await _weatherService.getHistoricalWeather(
          lat: lat,
          lon: lon,
          date: dataNascimento,
        );
      } catch (_) {
        // Fallback silencioso — clima pode não estar disponível para todas as datas
        climaData = {'descricao': 'Dados climáticos não disponíveis'};
      }
    }

    // 3. Extrai campos do país
    final nome = pais['name']?['common'] ?? 'Desconhecido';
    final capital = (pais['capital'] as List?)?.isNotEmpty == true
        ? pais['capital'][0]
        : null;
    final idioma = pais['languages'] != null
        ? (pais['languages'] as Map).values.first.toString()
        : null;
    final populacao = pais['population'] as int?;
    final moedaMap = pais['currencies'] as Map?;
    String? moeda;
    if (moedaMap != null && moedaMap.isNotEmpty) {
      final moedaKey = moedaMap.keys.first;
      final moedaNome = moedaMap[moedaKey]?['name'] ?? moedaKey;
      moeda = '$moedaNome ($moedaKey)';
    }
    final bandeiraUrl = pais['flags']?['png'];

    // 4. Expectativa de vida por região (aproximação pois REST Countries não tem esse campo diretamente)
    final expectativaVida = _expectativaPorRegiao(pais['region'] ?? '');

    return VidaAlternativaModel(
      usuarioId: usuarioId,
      paisCode: pais['cca2'] ?? '??',
      paisNome: nome,
      capital: capital,
      idioma: idioma,
      populacao: populacao,
      expectativaVida: expectativaVida,
      moeda: moeda,
      climaNascimento: jsonEncode(climaData),
      bandeiraUrl: bandeiraUrl,
    );
  }

  double _expectativaPorRegiao(String regiao) {
    // Valores médios aproximados por região (OMS 2023)
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
}