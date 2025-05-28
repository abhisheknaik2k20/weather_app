import 'package:flutter/material.dart';

class LocationDisplay extends StatelessWidget {
  const LocationDisplay({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.red, size: 30),
            const Text(
              'Mumbai',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 25,
              ),
            ),
          ],
        ),
        const Text(
          '28th March, Wednesday',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
      ],
    ),
  );
}
