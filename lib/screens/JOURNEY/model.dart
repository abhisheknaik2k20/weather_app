import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import 'package:my_app/API_KEY.dart';

class Model {
  Future<String> analyzeJourney(LatLng fromLocation, LatLng toLocation) async {
    final weatherData = await Future.wait([
      _getWeatherData(fromLocation),
      _getWeatherData(toLocation),
    ]);

    final fromWeather = weatherData[0];
    final toWeather = weatherData[1];

    if (fromWeather == null || toWeather == null) {
      throw Exception(
        'Unable to fetch weather data. Please check your connection.',
      );
    }

    return await _getGeminiAnalysis(fromWeather, toWeather);
  }

  Future<Map<String, dynamic>?> _getWeatherData(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://api.weatherapi.com/v1/forecast.json?'
        'q=${location.latitude},${location.longitude}&'
        'days=1&key=$weather_API_KEY',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));
      return response.statusCode == 200 ? json.decode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<String> _getGeminiAnalysis(
    Map<String, dynamic> fromWeather,
    Map<String, dynamic> toWeather,
  ) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: gemini_Api_Key,
      );
      final prompt = _buildAnalysisPrompt(fromWeather, toWeather);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? '## ❌ Error\n\nUnable to generate analysis.';
    } catch (e) {
      return '## ❌ Error\n\nFailed to generate analysis: ${e.toString()}';
    }
  }

  String _buildAnalysisPrompt(
    Map<String, dynamic> fromWeather,
    Map<String, dynamic> toWeather,
  ) {
    final fromCurrent = fromWeather['current'];
    final toCurrent = toWeather['current'];
    final fromLocation = fromWeather['location'];
    final toLocation = toWeather['location'];
    final fromForecast = fromWeather['forecast']?['forecastday']?[0];
    final toForecast = toWeather['forecast']?['forecastday']?[0];

    return '''
Analyze weather conditions for travel between locations. Format response in markdown with clear sections and emojis.

**FROM:** ${fromLocation['name']}, ${fromLocation['region']}
- Temperature: ${fromCurrent['temp_c']}°C (feels ${fromCurrent['feelslike_c']}°C)
- Condition: ${fromCurrent['condition']['text']}
- Wind: ${fromCurrent['wind_kph']} km/h, Visibility: ${fromCurrent['vis_km']} km
- Humidity: ${fromCurrent['humidity']}%, UV: ${fromCurrent['uv']}
${fromForecast != null ? '- Rain chance: ${fromForecast['day']['daily_chance_of_rain']}%' : ''}

**TO:** ${toLocation['name']}, ${toLocation['region']}
- Temperature: ${toCurrent['temp_c']}°C (feels ${toCurrent['feelslike_c']}°C)
- Condition: ${toCurrent['condition']['text']}
- Wind: ${toCurrent['wind_kph']} km/h, Visibility: ${toCurrent['vis_km']} km
- Humidity: ${toCurrent['humidity']}%, UV: ${toCurrent['uv']}
${toForecast != null ? '- Rain chance: ${toForecast['day']['daily_chance_of_rain']}%' : ''}

Provide markdown formatted analysis with:
## 🚦 Safety Status
(✅ Safe / ⚠️ Caution / ❌ Unsafe)

## ⚠️ Key Concerns
(bullet points of weather issues)

## 🎒 Recommendations
(what to pack/prepare)

## ⏰ Best Travel Time
(timing suggestions)

Keep concise (~200 words) with clear formatting and emojis.
''';
  }
}
