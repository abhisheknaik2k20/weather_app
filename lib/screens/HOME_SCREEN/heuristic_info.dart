import 'package:flutter/material.dart';

class HeuristicWeatherInfo extends StatelessWidget {
  const HeuristicWeatherInfo({super.key});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        " 98°",
        style: TextStyle(
          color: Colors.white,
          fontSize: MediaQuery.sizeOf(context).height * 0.1,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        "Thunderstorm",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
