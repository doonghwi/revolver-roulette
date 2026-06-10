import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dailyapp_stats.dart';
import 'game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DailyAppStats.recordOpen(
    appId: 'revolver_roulette',
    name: '🔫 리볼버 룰렛',
    desc: '오프라인 6연발 러시안룰렛 · 탭 방아쇠 · 명중 시 빨간 화면',
    platforms: ['web', 'android', 'offline'],
    webUrl: 'https://doonghwi.github.io/revolver-roulette/',
    repoUrl: 'https://github.com/doonghwi/revolver-roulette',
    day: 'Day 2',
  );
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
