import 'package:flutter/material.dart';

void main() {
  runApp(const HabitOneApp());
}

class HabitOneApp extends StatelessWidget {
  const HabitOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1일 1습관',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system, // 다크모드 대응
      home: const Scaffold(
        body: Center(child: Text('1일 1습관')),
      ),
    );
  }
}