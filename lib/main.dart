import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/forager_game.dart';
import 'ui/hud.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ForagerApp());
}

class ForagerApp extends StatefulWidget {
  const ForagerApp({super.key});
  @override
  State<ForagerApp> createState() => _ForagerAppState();
}

class _ForagerAppState extends State<ForagerApp> {
  late final ForagerGame game = ForagerGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forager Clone',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF3aa6e8),
        body: Stack(
          children: [
            GameWidget(game: game),
            Hud(game: game),
          ],
        ),
      ),
    );
  }
}
