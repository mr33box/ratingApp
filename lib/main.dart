import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const RatingApp());
}

class RatingApp extends StatefulWidget {
  const RatingApp({super.key});

  @override
  State<RatingApp> createState() => _RatingAppState();
}

class _RatingAppState extends State<RatingApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rating App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: HomePage(
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
