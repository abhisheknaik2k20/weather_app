import 'package:flutter/material.dart';
import 'package:my_app/providers/service_provider.dart';

class ExtraInfo extends StatefulWidget {
  const ExtraInfo({super.key});

  @override
  State<ExtraInfo> createState() => _ExtraInfoState();
}

class _ExtraInfoState extends State<ExtraInfo> {
  String humidity = "Fetching...";
  String windSpeed = "Fetching...";
  String visibility = "Fetching...";
  late final CentralizedWeatherService _weatherService;

  @override
  void initState() {
    super.initState();
    _weatherService = CentralizedWeatherService();
    _weatherService.addListener(_onWeatherDataUpdated);
    _getData();
  }

  @override
  void dispose() {
    _weatherService.removeListener(_onWeatherDataUpdated);
    super.dispose();
  }

  void _onWeatherDataUpdated() {
    if (mounted) {
      _getData();
    }
  }

  // This will be called when the widget is rebuilt
  @override
  void didUpdateWidget(ExtraInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _getData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  "Humidity",
                  "$humidity%",
                  Icons.water_drop,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  "Wind Speed",
                  "$windSpeed km/h",
                  Icons.air,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  "Visibility",
                  "$visibility km",
                  Icons.visibility,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 35, color: Colors.blue),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _getData() async {
    try {
      // Use the centralized weather service instead of direct SharedPreferences access
      final weatherData = await _weatherService.getCurrentWeatherData();

      if (weatherData != null && weatherData['current'] != null) {
        final current = weatherData['current'];

        if (mounted) {
          setState(() {
            humidity = current['humidity']?.toString() ?? "N/A";
            windSpeed = current['wind_kph']?.toString() ?? "N/A";
            visibility = current['vis_km']?.toString() ?? "N/A";
          });
        }
      } else {
        print('No weather data available from service');
        if (mounted) {
          setState(() {
            humidity = "No data";
            windSpeed = "No data";
            visibility = "No data";
          });
        }
      }
    } catch (e) {
      print('Error loading weather data: $e');
      if (mounted) {
        setState(() {
          humidity = "Error";
          windSpeed = "Error";
          visibility = "Error";
        });
      }
    }
  }
}
