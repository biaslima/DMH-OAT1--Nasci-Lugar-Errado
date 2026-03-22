import 'dart:math';
import 'package:dio/dio.dart';
import '../data/models/vida_alternativa_model.dart';

class CountriesService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://restcountries.com/v3.1'));

  Future<VidaAlternativaModel> getRandomCountry(int usuarioId) async {
    try {
      final response = await _dio.get(
          '/all?fields=name,capital,population,languages,currencies,flags,latlng,cca3'
      );

      final List<dynamic> countries = response.data;
      final random = Random();

      final country = countries[random.nextInt(countries.length)];

      final name = country['name']['common'] ?? 'Desconhecido';
      final capital = (country['capital'] as List).isNotEmpty ? country['capital'][0] : 'N/A';

      final langMap = country['languages'] as Map<String, dynamic>? ?? {};
      final idioma = langMap.isNotEmpty ? langMap.values.first : 'N/A';

      final currencyMap = country['currencies'] as Map<String, dynamic>? ?? {};
      String moeda = 'N/A';
      if (currencyMap.isNotEmpty) {
        final key = currencyMap.keys.first;
        moeda = "${currencyMap[key]['name']} (${currencyMap[key]['symbol'] ?? key})";
      }

      return VidaAlternativaModel(
        usuarioId: usuarioId,
        paisCode: country['cca3'] ?? 'UNK',
        paisNome: name,
        capital: capital,
        idioma: idioma,
        populacao: country['population'],
        moeda: moeda,
        bandeiraUrl: country['flags']['png'] ?? country['flags']['svg'],
        climaNascimento: "${country['latlng'][0]},${country['latlng'][1]}",
        expectativaVida: 75.0,
      );
    } catch (e) {
      throw Exception('Erro ao buscar países: $e');
    }
  }
}