import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:my_app/providers/service_provider.dart';

enum Animations {
  loading("assets/animations/Loading.json"),
  cloudy("assets/animations/Cloudy.json"),
  partrain("assets/animations/Part-Rain.json"),
  snow("assets/animations/Snow.json"),
  sunny("assets/animations/Sunny.json"),
  thunderStorm("assets/animations/ThunderStorm.json");

  final String path;
  const Animations(this.path);
}

class WeatherAnimation extends StatefulWidget {
  const WeatherAnimation({super.key});

  @override
  State<WeatherAnimation> createState() => _WeatherAnimationState();
}

class _WeatherAnimationState extends State<WeatherAnimation> {
  Animations animation = Animations.loading;
  late final CentralizedWeatherService _weatherService;

  @override
  void initState() {
    super.initState();
    _weatherService = CentralizedWeatherService()
      ..addListener(_updateAnimation);
    _updateAnimation();
  }

  @override
  void dispose() {
    _weatherService.removeListener(_updateAnimation);
    super.dispose();
  }

  @override
  void didUpdateWidget(WeatherAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.25,
    child: Lottie.asset(animation.path, fit: BoxFit.contain),
  );

  void _updateAnimation() async {
    if (!mounted) return;

    try {
      final weatherData = await _weatherService.getCurrentWeatherData();
      final condition =
          weatherData?['current']?['condition']?['text'] as String?;

      if (condition != null && mounted) {
        setState(() => animation = _getAnimationFromCondition(condition));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching weather data: $e')),
      );
    }
  }

  Animations _getAnimationFromCondition(String condition) {
    if (condition.contains(RegExp(r'Sunny|Clear|Partly Cloudy'))) {
      return Animations.sunny;
    }
    if (condition.contains(RegExp(r'Cloudy|Mist'))) return Animations.cloudy;
    if (condition.contains(RegExp(r'Rain|Drizzle|Showers'))) {
      return Animations.partrain;
    }
    if (condition.contains('Snow')) return Animations.snow;
    if (condition.contains('Thunderstorm')) return Animations.thunderStorm;
    return Animations.loading;
  }
}
