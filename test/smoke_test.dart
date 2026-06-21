import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forager_clone/game/forager_game.dart';
import 'package:forager_clone/game/resource_node.dart';

void main() {
  testWidgets('game loads, spawns world, and harvest works', (tester) async {
    final game = ForagerGame();

    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));

      // allow async onLoad (asset decode) + first frames
      Future<void> frames(int n) async {
        for (var i = 0; i < n; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 16));
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      for (var i = 0; i < 40 && !game.isLoaded; i++) {
        await frames(1);
      }
      expect(game.isLoaded, isTrue, reason: 'game should finish onLoad');
      await frames(5); // mount queued children

      final resources =
          game.world.children.whereType<ResourceNode>().toList();
      expect(resources.isNotEmpty, isTrue, reason: 'home island has resources');

      // harvest a node to death
      final node = resources.first;
      game.player.position.setFrom(node.position);
      final xpBefore = (game.state.level - 1) * 1000 + game.state.xp;

      for (var i = 0; i < 12 && node.isMounted; i++) {
        game.attackCooldown = 0;
        game.doAttack();
        await frames(2);
      }

      expect(node.isMounted, isFalse,
          reason: 'harvested node should be removed');
      final xpAfter = (game.state.level - 1) * 1000 + game.state.xp;
      expect(xpAfter > xpBefore, isTrue, reason: 'harvesting should grant xp');
    });
  });
}
