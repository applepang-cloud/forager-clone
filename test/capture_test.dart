import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forager_clone/game/forager_game.dart';
import 'package:forager_clone/game/enemy.dart';
import 'package:forager_clone/game/animal.dart';
import 'package:forager_clone/game/building.dart';
import 'package:forager_clone/game/audio.dart';

void main() {
  Audio.testMode = true;

  testWidgets('capture a rendered frame to PNG', (tester) async {
    final game = ForagerGame();
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 520, height: 340, child: GameWidget(game: game)),
      ));
      Future<void> frames(int n) async {
        for (var i = 0; i < n; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 16));
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      for (var i = 0; i < 40 && !game.isLoaded; i++) {
        await frames(1);
      }
      await frames(8);

      // showcase new content near the player
      final p = game.player.position;
      game.state.ownedPlots.add('east');
      game.world.add(Enemy(EnemyKind.slime, p + Vector2(80, -10)));
      game.world.add(Enemy(EnemyKind.wraith, p + Vector2(150, -60)));
      game.world.add(Enemy(EnemyKind.bossSlime, p + Vector2(120, 70)));
      game.world.add(Animal(AnimalKind.cow, p + Vector2(-90, 30)));
      game.world.add(Animal(AnimalKind.chicken, p + Vector2(-60, -50)));
      game.world.add(Building(BuildingType.steelwork, p + Vector2(-150, 80)));
      game.world.add(Building(BuildingType.anvil, p + Vector2(40, 110)));
      game.state.addItem('wood', 12);
      game.state.addItem('stone', 8);
      game.state.addItem('leather', 2);
      game.state.addItem('coal', 3);
      game.state.addCoins(60);
      await frames(12);

      final size = game.size;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF3aa6e8),
      );
      game.renderTree(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.x.toInt(), size.y.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('preview_capture.png');
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
      expect(file.existsSync(), isTrue);
      // ignore: avoid_print
      print('WROTE ${file.absolute.path} (${bytes.lengthInBytes} bytes)');
    });
  });
}
