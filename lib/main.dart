import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ChromaniacApp());
}

class ChromaniacApp extends StatelessWidget {
  const ChromaniacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chromaniac',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
