import './splash_screen.dart';
import 'package:flutter/material.dart';

const String baseUrl = "capstone1218.azurewebsites.net";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Century-Gothic'),
      home: SplashScreen(),
    );
  }
}
