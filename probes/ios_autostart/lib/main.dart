import 'package:flutter/material.dart';

void main() {
  runApp(const ProbeApp());
}

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});

  static const String appTitle = 'BikeTrack Probe';
  static const String buildNumber = '1.0.0+1';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: appTitle, home: ProbeHomePage());
  }
}

class ProbeHomePage extends StatelessWidget {
  const ProbeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ProbeApp.appTitle)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(ProbeApp.buildNumber),
            SizedBox(height: 16),
            Text('Probe shell OK'),
          ],
        ),
      ),
    );
  }
}
