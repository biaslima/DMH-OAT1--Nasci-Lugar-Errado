import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class CountriesService {
  // Singleton
  static final CountriesService _instance = CountriesService._internal();
  factory CountriesService() => _instance;
  CountriesService._internal();

  List<Map<String, dynamic>>? _cache;

  static const _fields =
      'cca2,name,capital,region,languages,population,currencies,latlng,flags';

  static const _baseUrl = 'https://restcountries.com/v3.1';

  Future<List<Map<String, dynamic>>> getAllCountries() async {
    if (_cache != null) return _cache!;

    final uri = Uri.parse('$_baseUrl/all?fields=$_fields');

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception(
            'Tempo limite excedido. Verifique sua conexão e tente novamente.',
          ),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar países (HTTP ${response.statusCode}). Tente novamente.',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);
    _cache = data.cast<Map<String, dynamic>>();
    return _cache!;
  }

  Future<Map<String, dynamic>> getRandomCountry() async {
    final paises = await getAllCountries();
    final rng = math.Random();
    return paises[rng.nextInt(paises.length)];
  }

  void clearCache() => _cache = null;
}
