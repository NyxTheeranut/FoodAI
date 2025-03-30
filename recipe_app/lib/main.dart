import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart'; // Import Device Preview
import 'pages/landing_page.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Enable the device preview
      builder: (context) => const RecipeApp(), // Keep your RecipeApp as the main widget
    ),
  );
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const LandingPage(),
      debugShowCheckedModeBanner: false, // Hide debug banner for clean UI
      builder: DevicePreview.appBuilder, // Add this to apply device preview styles
    );
  }
}
