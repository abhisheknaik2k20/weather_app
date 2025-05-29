import 'package:flutter/material.dart';
import 'package:my_app/providers/service_provider.dart';

class HeuristicWeatherInfo extends StatefulWidget {
  const HeuristicWeatherInfo({super.key});

  @override
  State<HeuristicWeatherInfo> createState() => _HeuristicWeatherInfoState();
}

class _HeuristicWeatherInfoState extends State<HeuristicWeatherInfo> {
  String _temperature = "", _weather = "";
  late final CentralizedWeatherService _weatherService;

  @override
  void initState() {
    super.initState();
    (_weatherService = CentralizedWeatherService()).addListener(
      _loadWeatherData,
    );
    _loadWeatherData();
  }

  @override
  void dispose() {
    _weatherService.removeListener(_loadWeatherData);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HeuristicWeatherInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadWeatherData();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _temperature,
        style: TextStyle(
          color: Colors.white,
          fontSize: MediaQuery.sizeOf(context).height * 0.08,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        _weather,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Future<void> _loadWeatherData() async {
    if (!mounted) return;
    try {
      final data = await _weatherService.getCurrentWeatherData();
      final current = data?['current'];
      setState(() {
        _temperature = current != null ? "${current['temp_c']}°C" : "Error";
        _weather = current?['condition']?['text'] ?? "Unable to load";
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _temperature = "Error";
          _weather = "Unable to load";
        });
      }
    }
  }
}
