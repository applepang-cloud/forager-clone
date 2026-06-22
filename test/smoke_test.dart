import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forager_clone/game/forager_game.dart';
import 'package:forager_clone/game/resource_node.dart';
import 'package:forager_clone/game/arrow.dart';
import 'package:forager_clone/game/enemy.dart';
import 'package:forager_clone/game/game_state.dart';
import 'package:forager_clone/game/audio.dart';

void main() {
  Audio.testMode = true;

  test('GameState save round-trips', () {
    final s = GameState()
      ..maxHealth = 8
      ..health = 6
      ..level = 4
      ..coins = 99
      ..weapon = Weapon.bow;
    s.addItem('wood', 12);
    s.ownedPlots.add('g1_0');

    final s2 = GameState()..fromJson(s.toJson());
    expect(s2.maxHealth, 8);
    expect(s2.level, 4);
    expect(s2.coins, 99);
    expect(s2.weapon, Weapon.bow);
    expect(s2.inventory['wood'], 12);
    expect(s2.ownedPlots.contains('g1_0'), isTrue);
  });

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
        game.meleeSwing();
        await frames(2);
      }

      expect(node.isMounted, isFalse,
          reason: 'harvested node should be removed');
      final xpAfter = (game.state.level - 1) * 1000 + game.state.xp;
      expect(xpAfter > xpBefore, isTrue, reason: 'harvesting should grant xp');
    });
  });

  testWidgets('bow fires an arrow that damages an enemy', (tester) async {
    final game = ForagerGame();
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      Future<void> frames(int n) async {
        for (var i = 0; i < n; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 16));
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      for (var i = 0; i < 40 && !game.isLoaded; i++) {
        await frames(1);
      }
      await frames(3);

      // equip bow, place an enemy to the right, aim and fire fully charged
      game.state.setWeapon(Weapon.bow);
      game.player.facing.setValues(1, 0);
      final enemy = Enemy(EnemyKind.slime, game.player.position + Vector2(90, 0));
      game.world.add(enemy);
      await frames(2);
      final hpBefore = enemy.hp;

      game.attackCooldown = 0;
      game.fireArrow(1.0);
      await frames(1);
      expect(game.world.children.whereType<PlayerArrow>().isNotEmpty, isTrue,
          reason: 'an arrow should be in flight');
      await frames(20);

      expect(enemy.hp < hpBefore || !enemy.isMounted, isTrue,
          reason: 'arrow should damage/kill the enemy');
    });
  });
}
