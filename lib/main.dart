import 'package:flutter/material.dart';
import 'package:stationx/landing/landing_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Station X',
      debugShowCheckedModeBanner: false,
      home: const LandingPage(),
    );
  }
}
