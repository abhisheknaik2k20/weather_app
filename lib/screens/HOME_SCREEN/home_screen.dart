import 'package:flutter/material.dart';
import 'package:my_app/providers/service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/animations/weather_animation.dart';
import 'package:my_app/screens/HOME_SCREEN/heuristic_info.dart';
import 'package:my_app/screens/HOME_SCREEN/location_info.dart';
import 'package:my_app/screens/HOME_SCREEN/more_info.dart';
import 'package:my_app/screens/HOME_SCREEN/stats.dart';
import 'package:my_app/screens/HOME_SCREEN/time_line.dart';

class MyHomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const MyHomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoadingWeather = false;
  final CentralizedWeatherService _weatherService = CentralizedWeatherService();
  int _rebuildCounter = 0;

  static final List<Widget Function(Key)> _itemBuilders = [
    (key) => ExtraInfo(key: key),
    (key) => WeatherTimeline(key: key),
    (key) => TemperatureGraphWidget(key: key),
  ];

  @override
  void initState() {
    super.initState();
    _weatherService.addListener(_onWeatherDataUpdated);
    _loadWeatherData();
  }

  @override
  void dispose() {
    _weatherService.removeListener(_onWeatherDataUpdated);
    super.dispose();
  }

  void _onWeatherDataUpdated() {
    if (mounted) setState(() => _rebuildCounter++);
  }

  Future<void> _loadWeatherData() async {
    if (!mounted) return;

    setState(() => _isLoadingWeather = true);

    try {
      await Future.wait([
        _weatherService.getCurrentWeatherData(),
        _weatherService.getForecastWeatherData(),
      ]);
    } catch (e) {
      debugPrint('Error loading weather data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _onLocationChanged(double latitude, double longitude) async {
    if (!mounted) return;

    setState(() => _isLoadingWeather = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setDouble('last_latitude', latitude),
        prefs.setDouble('last_longitude', longitude),
        _weatherService.refreshAllWeatherData(),
      ]);
    } catch (e) {
      debugPrint('Error updating location: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: isDark ? Colors.indigo.shade800 : Colors.blue,
            title: LocationDisplay(onLocationChanged: _onLocationChanged),
            expandedHeight: screenHeight * 0.35,
            stretch: true,
            onStretchTrigger: () async {},
            stretchTriggerOffset: 300.0,
            actions: [
              if (_isLoadingWeather)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: widget.onThemeToggle,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.indigo.shade900,
                            Colors.indigo.shade700,
                            Colors.indigo.shade900,
                          ]
                        : [Colors.blue, Colors.blueAccent, Colors.lightBlue],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeuristicWeatherInfo(
                      key: ValueKey('heuristic_$_rebuildCounter'),
                    ),
                    WeatherAnimation(
                      key: ValueKey('animation_$_rebuildCounter'),
                    ),
                  ],
                ),
              ),
              stretchModes: const [StretchMode.zoomBackground],
            ),
          ),
          SliverList.builder(
            itemCount: _itemBuilders.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.01)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
              ),
              child: _itemBuilders[index](
                ValueKey('item_${index}_$_rebuildCounter'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
