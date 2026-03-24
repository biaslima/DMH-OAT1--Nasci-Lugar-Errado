import 'dart:math';
import 'package:dio/dio.dart';

class CountriesService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://restcountries.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  List<Map<String, dynamic>>? _cache;

  Future<List<Map<String, dynamic>>> getAllCountries() async {
    if (_cache != null) return _cache!;

    try {
      final response = await _dio.get(
        '/v3.1/all',
        queryParameters: {
          'fields': 'name,cca2,capital,population,languages,currencies,flags,latlng,region',
        },
      );
      _cache = List<Map<String, dynamic>>.from(response.data as List);
      return _cache!;
    } on DioException catch (e) {
      throw Exception('Erro ao buscar países: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getRandomCountry() async {
    final countries = await getAllCountries();
    return countries[Random().nextInt(countries.length)];
  }
}