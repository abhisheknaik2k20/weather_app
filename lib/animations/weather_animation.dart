import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum Animations {
  cloudy("assets/animations/Cloudy.json"),
  partrain("assets/animations/Part-Rain.json"),
  snow("assets/animations/Snow.json"),
  sunny("assets/animations/Sunny.json"),
  thunderStorm("assets/animations/ThunderStorm.json");

  final String path;
  const Animations(this.path);
}

class WeatherAnimation extends StatelessWidget {
  final Animations animation;
  const WeatherAnimation({super.key, required this.animation});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.25,
    child: Lottie.asset(animation.path, fit: BoxFit.contain),
  );
}
