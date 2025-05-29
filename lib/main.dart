import 'package:flutter/material.dart';
import 'package:my_app/screens/BLACK_SCREEN/black_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool('isDarkMode') ?? true);
  }

  _saveThemePreference(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
    _saveThemePreference(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Demo',
    debugShowCheckedModeBanner: false,
    theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
    home: BlackScreen(isDarkMode: _isDarkMode, onThemeToggle: _toggleTheme),
  );
}
