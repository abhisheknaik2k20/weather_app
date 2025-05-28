import 'package:flutter/material.dart';
import 'package:my_app/animations/weather_animation.dart';
import 'package:my_app/screens/HOME_SCREEN/heuristic_info.dart';
import 'package:my_app/screens/HOME_SCREEN/location_info.dart';
import 'package:my_app/screens/HOME_SCREEN/more_info.dart';

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
  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: widget.isDarkMode
              ? Colors.indigo.shade800
              : Colors.blue,
          title: LocationDisplay(),
          expandedHeight: MediaQuery.of(context).size.height * 0.33,
          stretch: true,
          onStretchTrigger: () async {},
          stretchTriggerOffset: 300.0,
          actions: [
            IconButton(
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
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
                  colors: widget.isDarkMode
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
                  HeuristicWeatherInfo(),
                  WeatherAnimation(animation: Animations.sunny),
                ],
              ),
            ),
            stretchModes: const [StretchMode.zoomBackground],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.01)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: widget.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: items[index],
            ),
            childCount: items.length,
          ),
        ),
      ],
    ),
  );
}

List<Widget> items = [ExtraInfo()];
