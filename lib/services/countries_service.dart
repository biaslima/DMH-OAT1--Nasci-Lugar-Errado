import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class CountriesService {
  static final CountriesService _instance = CountriesService._internal();
  factory CountriesService() => _instance;
  CountriesService._internal();

  static const String _baseUrl = 'https://restcountries.com/v3.1';
  static const String _fields =
      'cca2,name,capital,region,languages,population,currencies,latlng,flags';

  List<Map<String, dynamic>>? _cache;

  Future<List<Map<String, dynamic>>> getAllCountries() async {
    if (_cache != null) return _cache!;

    final uri = Uri.parse('$_baseUrl/all?fields=$_fields');

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception(_timeoutMessage),
        );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar países (HTTP ${response.statusCode}).');
    }

    final List<dynamic> data = jsonDecode(response.body);
    _cache = data.cast<Map<String, dynamic>>();

    return _cache!;
  }

  Future<Map<String, dynamic>> getRandomCountry() async {
    final paises = await getAllCountries();

    if (paises.isEmpty) {
      throw Exception('Nenhum país encontrado.');
    }

    final randomIndex = math.Random().nextInt(paises.length);
    return paises[randomIndex];
  }

  void clearCache() => _cache = null;

  // ================== MENSAGENS ==================

  static const String _timeoutMessage =
      'Tempo limite excedido. Verifique sua conexão.';
}
