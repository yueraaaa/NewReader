import 'package:flutter/material.dart';

void main() {
  runApp(const RealReaderApp());
}

class RealReaderApp extends StatelessWidget {
  const RealReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Reader',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('Real Reader - Scaffold')),
      ),
    );
  }
}
