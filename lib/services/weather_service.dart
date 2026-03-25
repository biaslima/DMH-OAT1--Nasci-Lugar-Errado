import 'package:dio/dio.dart';

class WeatherService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 15),
    ),
  );

  static const String _baseUrl = 'https://archive-api.open-meteo.com';

  Future<Map<String, dynamic>> getHistoricalWeather({
    required double lat,
    required double lon,
    required String date,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/archive',
        queryParameters: _buildQuery(lat, lon, date),
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw Exception('Erro ao buscar clima: ${e.message}');
    }
  }

  // ================== HELPERS ==================

  Map<String, dynamic> _buildQuery(double lat, double lon, String date) {
    return {
      'latitude': lat,
      'longitude': lon,
      'start_date': date,
      'end_date': date,
      'daily':
          'weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum',
      'timezone': 'auto',
    };
  }

  Map<String, dynamic> _parseResponse(dynamic data) {
    final daily = data['daily'] as Map?;

    if (daily == null) {
      return _fallback();
    }

    final codes = (daily['weathercode'] as List?) ?? [];
    final temps = (daily['temperature_2m_max'] as List?) ?? [];

    final code = codes.isNotEmpty ? codes.first as int? : null;
    final temp = temps.isNotEmpty ? (temps.first as num?)?.toDouble() : null;

    return {
      'temperatura_max': temp,
      'weathercode': code,
      'descricao': _descricaoClima(code),
    };
  }

  Map<String, dynamic> _fallback() {
    return {'descricao': 'Dados climáticos não disponíveis'};
  }

  String _descricaoClima(int? code) {
    if (code == null) return 'Clima desconhecido';
    if (code == 0) return 'Céu limpo';
    if (code <= 3) return 'Parcialmente nublado';
    if (code <= 49) return 'Neblina ou névoa';
    if (code <= 59) return 'Garoa leve';
    if (code <= 69) return 'Chuva';
    if (code <= 79) return 'Neve';
    if (code <= 82) return 'Pancadas de chuva';
    if (code <= 84) return 'Chuva forte';
    if (code <= 99) return 'Tempestade com raios';
    return 'Clima variado';
  }
}
