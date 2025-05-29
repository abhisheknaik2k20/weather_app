// ignore_for_file: depend_on_referenced_packages, avoid_function_literals_in_foreach_calls, unrelated_type_equality_checks

import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_app/API_KEY.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CentralizedWeatherService {
  static const String _currentDataKey = 'cached_current_weather',
      _forecastDataKey = 'cached_forecast_weather';
  static const String _currentUpdateKey = 'last_current_update',
      _forecastUpdateKey = 'last_forecast_update';

  static final CentralizedWeatherService _instance =
      CentralizedWeatherService._internal();
  factory CentralizedWeatherService() => _instance;
  CentralizedWeatherService._internal();

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback callback) => _listeners.add(callback);
  void removeListener(VoidCallback callback) => _listeners.remove(callback);
  void _notifyListeners() => _listeners.forEach((callback) => callback());

  Future<Map<String, dynamic>?> getCurrentWeatherData() => _getWeatherData(
    _currentDataKey,
    _currentUpdateKey,
    'https://api.weatherapi.com/v1/current.json?q={lat}%2C{lng}&key=$weather_API_KEY',
  );

  Future<Map<String, dynamic>?> getForecastWeatherData() => _getWeatherData(
    _forecastDataKey,
    _forecastUpdateKey,
    'https://api.weatherapi.com/v1/forecast.json?q={lat}%2C{lng}&days=9&alerts=yes&key=$weather_API_KEY',
  );

  Future<void> refreshAllWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_currentUpdateKey),
      prefs.remove(_forecastUpdateKey),
      getCurrentWeatherData(),
      getForecastWeatherData(),
    ]);
  }

  Future<Map<String, dynamic>?> _getWeatherData(
    String dataKey,
    String updateKey,
    String apiUrl,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final hasInternet =
        (await Connectivity().checkConnectivity()) != ConnectivityResult.none;

    if (hasInternet && !_isCacheValid(prefs, updateKey)) {
      final data = await _fetchFromAPI(apiUrl);
      if (data != null) {
        await _saveData(prefs, dataKey, updateKey, data);
        _notifyListeners();
        return data;
      }
    }
    return _loadCachedData(prefs, dataKey);
  }

  bool _isCacheValid(SharedPreferences prefs, String updateKey) {
    final timestamp = prefs.getInt(updateKey);
    return timestamp != null &&
        DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(timestamp))
                .inHours <
            1;
  }

  Future<void> _saveData(
    SharedPreferences prefs,
    String dataKey,
    String updateKey,
    Map<String, dynamic> data,
  ) async {
    await Future.wait([
      prefs.setString(dataKey, json.encode(data)),
      prefs.setInt(updateKey, DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  Map<String, dynamic>? _loadCachedData(
    SharedPreferences prefs,
    String dataKey,
  ) {
    final jsonString = prefs.getString(dataKey);
    return jsonString != null ? json.decode(jsonString) : null;
  }

  Future<Map<String, dynamic>?> _fetchFromAPI(String apiTemplate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_latitude'),
          lng = prefs.getDouble('last_longitude');
      if (lat == null || lng == null) return null;

      final response = await http
          .get(
            Uri.parse(
              apiTemplate
                  .replaceAll('{lat}', '$lat')
                  .replaceAll('{lng}', '$lng'),
            ),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200 ? json.decode(response.body) : null;
    } catch (e) {
      return null;
    }
  }
}
