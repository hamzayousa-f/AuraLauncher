import 'package:flutter/material.dart';
import 'features/home/presentation/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuraLauncher());
}

class AuraLauncher extends StatelessWidget {
  const AuraLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const HomeView(),
    );
  }
}
