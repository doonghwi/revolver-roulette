import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait: lock to portrait orientations.
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const RevolverRouletteApp());
}

class RevolverRouletteApp extends StatelessWidget {
  const RevolverRouletteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revolver Roulette',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFc0392b),
          brightness: Brightness.dark,
        ),
        fontFamily: 'monospace',
      ),
      home: const GameScreen(),
    );
  }
}
