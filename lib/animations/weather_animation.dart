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

class _WeatherAnimationState extends State<WeatherAnimation>
    with WidgetsBindingObserver {
  Animations animation = Animations.loading;
  late final CentralizedWeatherService _weatherService;
  String? _lastCondition;
  bool _hasInitialData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _weatherService = CentralizedWeatherService()
      ..addListener(_updateAnimation);
    _updateAnimation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weatherService.removeListener(_updateAnimation);
    super.dispose();
  }

  @override
  void didUpdateWidget(WeatherAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateAnimation();
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.25,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      child: Lottie.asset(
        animation.path,
        key: ValueKey(animation.path),
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
      ),
    ),
  );

  void _updateAnimation() async {
    if (!mounted) return;

    try {
      final weatherData = await _weatherService.getCurrentWeatherData();
      final condition =
          weatherData?['current']?['condition']?['text'] as String?;

      if (condition != null && mounted) {
        if (_lastCondition != condition || !_hasInitialData) {
          _lastCondition = condition;
          _hasInitialData = true;

          final newAnimation = _getAnimationFromCondition(condition);

          if (newAnimation != animation) {
            setState(() => animation = newAnimation);
          }
        }
      } else if (!_hasInitialData && mounted) {
        setState(() => animation = Animations.loading);
      }
    } catch (e) {
      debugPrint('Error loading weather animation: $e');
      if (!_hasInitialData && mounted) {
        setState(() => animation = Animations.loading);
      }
    }
  }

  Animations _getAnimationFromCondition(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (_matchesPattern(lowerCondition, [
      'sunny',
      'clear',
      'partly cloudy',
      'fair',
      'bright',
    ])) {
      return Animations.sunny;
    }

    if (_matchesPattern(lowerCondition, [
      'cloudy',
      'mist',
      'overcast',
      'fog',
      'haze',
      'mostly cloudy',
    ])) {
      return Animations.cloudy;
    }

    if (_matchesPattern(lowerCondition, [
      'rain',
      'drizzle',
      'showers',
      'precipitation',
      'sprinkle',
      'light rain',
      'moderate rain',
      'heavy rain',
    ])) {
      return Animations.partrain;
    }

    if (_matchesPattern(lowerCondition, [
      'snow',
      'blizzard',
      'flurries',
      'sleet',
      'ice',
      'freezing',
    ])) {
      return Animations.snow;
    }

    if (_matchesPattern(lowerCondition, [
      'thunderstorm',
      'thunder',
      'lightning',
      'storm',
      'severe',
    ])) {
      return Animations.thunderStorm;
    }

    return _hasInitialData ? Animations.sunny : Animations.loading;
  }

  bool _matchesPattern(String condition, List<String> patterns) {
    return patterns.any((pattern) => condition.contains(pattern));
  }
}
