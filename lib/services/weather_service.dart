import 'package:dio/dio.dart';

class WeatherService {
  final _dio = Dio(BaseOptions(baseUrl: 'https://archive-api.open-meteo.com/v1'));

  Future<String> getHistoricalWeather(double lat, double lon, String date) async {
    try {
      final res = await _dio.get('/archive', queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'start_date': date,
        'end_date': date,
        'daily': 'weather_code,temperature_2m_max',
        'timezone': 'auto',
      });

      final code = res.data['daily']['weather_code'][0];
      final temp = res.data['daily']['temperature_2m_max'][0];
      return "${_mapWeatherCode(code)} ($temp°C)";
    } catch (e) {
      return "Clima não disponível";
    }
  }

  String _mapWeatherCode(int code) {
    if (code == 0) return "Céu limpo";
    if (code <= 3) return "Parcialmente nublado";
    if (code >= 51 && code <= 67) return "Chuva leve";
    return "Tempo instável";
  }
}