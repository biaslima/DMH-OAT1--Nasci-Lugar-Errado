import 'package:flutter/material.dart';
import '../data/models/vida_alternativa_model.dart';
import '../services/countries_service.dart';
import '../services/weather_service.dart';

class VidaProvider with ChangeNotifier {
  final _countriesService = CountriesService();
  final _weatherService = WeatherService();

  VidaAlternativaModel? _currentVida;
  bool _isLoading = false;

  VidaAlternativaModel? get currentVida => _currentVida;
  bool get isLoading => _isLoading;

  Future<void> sortearNovaVida(int usuarioId, String dataNascimento) async {
    _isLoading = true;
    notifyListeners();

    try {
      final vida = await _countriesService.getRandomCountry(usuarioId);

      final coords = vida.climaNascimento!.split(',');
      final clima = await _weatherService.getHistoricalWeather(
          double.parse(coords[0]),
          double.parse(coords[1]),
          dataNascimento
      );

      _currentVida = vida;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}