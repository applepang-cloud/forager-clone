import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'animal.dart';
import 'building.dart';
import 'drop.dart';
import 'enemy.dart';
import 'game_state.dart';
import 'player.dart';
import 'resource_node.dart';
import 'tile_map.dart';
import 'world_data.dart';

class _Respawn {
  double t;
  final ResourceType type;
  final Vector2 pos;
  _Respawn(this.t, this.type, this.pos);
}

class ForagerGame extends FlameGame
    with KeyboardEvents, TapDetector, HasCollisionDetection {
  final GameState state = GameState();

  late Player player;
  late TileMap tileMap;
  late JoystickComponent joystick;

  final _rng = Random();
  final List<_Respawn> _respawns = [];

  double attackCooldown = 0;
  double hitInvuln = 0;
  double enemySpawnTimer = 3;
  double animalSpawnTimer = 10;
  Vector2 _keyInput = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0xFF3aa6e8); // water

  @override
  Future<void> onLoad() async {
    tileMap = TileMap(state);
    world.add(tileMap);

    player = Player(homePlot.centerWorld);
    world.add(player);

    camera.viewfinder.visibleGameSize = Vector2(520, 340);
    camera.follow(player);

    // initial resources + animals on home
    spawnResourcesForPlot(homePlot, density: 0.16);
    spawnAnimalsForPlot(homePlot, 3);

    _addControls();
  }

  void _addControls() {
    final knobPaint = Paint()..color = const Color(0x88ffffff);
    final bgPaint = Paint()..color = const Color(0x44000000);
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 48, paint: bgPaint),
      margin: const EdgeInsets.only(left: 30, bottom: 30),
    );
    camera.viewport.add(joystick);

    final atkBtn = HudButtonComponent(
      button: CircleComponent(
          radius: 34, paint: Paint()..color = const Color(0x88e85a3a)),
      buttonDown: CircleComponent(
          radius: 34, paint: Paint()..color = const Color(0xcce85a3a)),
      margin: const EdgeInsets.only(right: 28, bottom: 40),
      onPressed: doAttack,
    );
    camera.viewport.add(atkBtn);

    final dashBtn = HudButtonComponent(
      button: CircleComponent(
          radius: 26, paint: Paint()..color = const Color(0x8844cc66)),
      buttonDown: CircleComponent(
          radius: 26, paint: Paint()..color = const Color(0xcc44cc66)),
      margin: const EdgeInsets.only(right: 96, bottom: 50),
      onPressed: () => player.tryDash(),
    );
    camera.viewport.add(dashBtn);
  }

  // ---- spawning ----
  bool _occupied(Vector2 p, double minDist) {
    for (final c in world.children) {
      if (c is ResourceNode && c.position.distanceTo(p) < minDist) return true;
    }
    return false;
  }

  void spawnResourcesForPlot(Plot plot, {double density = 0.13}) {
    for (int c = plot.col + 1; c < plot.col + plot.cols - 1; c++) {
      for (int r = plot.row + 1; r < plot.row + plot.rows - 1; r++) {
        if (_rng.nextDouble() > density) continue;
        final pos = Vector2((c + 0.5) * kTile, (r + 0.9) * kTile);
        if (_occupied(pos, 40)) continue;
        if (player.position.distanceTo(pos) < 70) continue;
        final roll = _rng.nextDouble();
        final type = roll < 0.5
            ? ResourceType.tree
            : roll < 0.8
                ? ResourceType.rock
                : ResourceType.berry;
        world.add(ResourceNode(type, pos));
      }
    }
  }

  void spawnAnimalsForPlot(Plot plot, int count) {
    for (int i = 0; i < count; i++) {
      final c = plot.col + 1 + _rng.nextInt(plot.cols - 2);
      final r = plot.row + 1 + _rng.nextInt(plot.rows - 2);
      final pos = Vector2((c + 0.5) * kTile, (r + 0.9) * kTile);
      final kind = _rng.nextBool() ? AnimalKind.cow : AnimalKind.chicken;
      world.add(Animal(kind, pos));
    }
  }

  void spawnEnemyAt(EnemyKind kind, Vector2 pos) {
    if (state.gameOver) return;
    world.add(Enemy(kind, pos));
  }

  void spawnEnemyBullet(Vector2 from, Vector2 target) {
    final dir = (target - from);
    if (dir.length2 == 0) return;
    world.add(EnemyProjectile(from.clone(), dir.normalized() * 150));
  }

  void spawnEnemy() {
    final ownedNonHome =
        plots.where((p) => p.id != 'home' && state.ownedPlots.contains(p.id));
    if (ownedNonHome.isEmpty) return;
    final list = ownedNonHome.toList();
    final plot = list[_rng.nextInt(list.length)];
    final c = plot.col + 1 + _rng.nextInt(plot.cols - 2);
    final r = plot.row + 1 + _rng.nextInt(plot.rows - 2);
    final pos = Vector2((c + 0.5) * kTile, (r + 0.9) * kTile);
    if (player.position.distanceTo(pos) < 120) return;
    final kind = plot.id.contains('north') && _rng.nextBool()
        ? EnemyKind.skull
        : EnemyKind.slime;
    world.add(Enemy(kind, pos));
  }

  int get _enemyCount => world.children.whereType<Enemy>().length;

  // ---- combat / interaction ----
  void doAttack() {
    if (attackCooldown > 0 || state.gameOver) return;
    attackCooldown = 0.32;
    player.attack();

    final center = player.position - Vector2(0, 14);
    const reach = 62.0;

    // hit nearest resource
    ResourceNode? nearest;
    double best = reach;
    for (final n in world.children.whereType<ResourceNode>()) {
      final d = n.position.distanceTo(center);
      if (d < best) {
        best = d;
        nearest = n;
      }
    }
    if (nearest != null) {
      spendStamina(6);
      if (nearest.hit()) {
        final cfg = nearest.cfg;
        final count = nearest.rollDropCount();
        for (int i = 0; i < count; i++) {
          world.add(DropItem(cfg.drop, nearest.position,
              () => player.position, _collect));
        }
        // bonus rare drops from rocks
        if (nearest.type == ResourceType.rock && _rng.nextDouble() < 0.3) {
          world.add(DropItem(_rng.nextBool() ? 'coal' : 'iron_ore',
              nearest.position, () => player.position, _collect));
        }
        gainXp(cfg.xp);
        _respawns.add(_Respawn(14, nearest.type, nearest.position.clone()));
        nearest.removeFromParent();
      }
    }

    // hit enemies in radius
    for (final e in world.children.whereType<Enemy>()) {
      if (e.position.distanceTo(center) < reach + 6) {
        spendStamina(2);
        e.takeHit(2, player.position);
      }
    }

    // harvest animals in radius
    for (final a in world.children.whereType<Animal>().toList()) {
      if (a.position.distanceTo(center) < reach) {
        spendStamina(4);
        if (a.takeHit()) {
          for (final id in a.cfg.drops) {
            world.add(
                DropItem(id, a.position, () => player.position, _collect));
          }
          gainXp(a.cfg.xp);
          a.removeFromParent();
        }
        break; // only the nearest-ish one per swing
      }
    }
  }

  void _collect(String id) {
    state.addItem(id, 1);
  }

  void gainXp(int n) {
    state.addXp(n, () {
      // level up: clear nearby enemies briefly? just heal (handled in state)
    });
  }

  void onEnemyKilled(Enemy e) {
    state.addCoins(e.cfg.coins);
    gainXp(e.cfg.xp);
    switch (e.kind) {
      case EnemyKind.bossSlime:
        // splits into a swarm of small slimes
        for (int i = 0; i < 4; i++) {
          final off = Vector2(_rng.nextDouble() * 60 - 30,
              _rng.nextDouble() * 60 - 30);
          spawnEnemyAt(EnemyKind.slime, e.position + off);
        }
        world.add(DropItem('jelly', e.position, () => player.position, _collect));
        world.add(DropItem('jelly', e.position, () => player.position, _collect));
        break;
      case EnemyKind.wraith:
        world.add(
            DropItem('skullhead', e.position, () => player.position, _collect));
        break;
      default:
        world.add(
            DropItem('jelly', e.position, () => player.position, _collect));
    }
  }

  // ---- buildings ----
  bool canAfford(Map<String, int> cost) {
    for (final e in cost.entries) {
      if ((state.inventory[e.key] ?? 0) < e.value) return false;
    }
    return true;
  }

  bool placeBuilding(BuildingType type) {
    if (state.gameOver) return false;
    final cfg = buildingConfigs[type]!;
    if (!canAfford(cfg.cost)) return false;
    cfg.cost.forEach((k, v) => state.spend(k, v));
    // place one tile in front of the player, snapped to land
    final dir = player.facing.length2 > 0 ? player.facing : Vector2(0, 1);
    var spot = player.position + dir.normalized() * kTile;
    final c = (spot.x / kTile).floor();
    final r = (spot.y / kTile).floor();
    if (!tileMap.isLand(c, r)) spot = player.position;
    world.add(Building(type, spot));
    return true;
  }

  void enemyTouch(int dmg) {
    if (hitInvuln > 0 || state.gameOver) return;
    hitInvuln = 0.9;
    spendStamina(10);
    damagePlayer(dmg);
  }

  void spendStamina(double amt) {
    state.stamina -= amt;
    if (state.stamina <= 0) {
      state.stamina = state.maxStamina;
      damagePlayer(1);
    }
    state.touch();
  }

  void damagePlayer(int n) {
    state.health -= n;
    player.hurt();
    if (state.health <= 0) {
      state.health = 0;
      state.gameOver = true;
    }
    state.touch();
  }

  // ---- land purchase ----
  bool isAdjacentToOwned(Plot plot) {
    for (final o in plots) {
      if (!state.ownedPlots.contains(o.id)) continue;
      final touchX = plot.col <= o.col + o.cols && plot.col + plot.cols >= o.col;
      final touchY = plot.row <= o.row + o.rows && plot.row + plot.rows >= o.row;
      if (touchX && touchY) return true;
    }
    return false;
  }

  List<Plot> purchasablePlots() {
    final list = plots
        .where((p) => !state.ownedPlots.contains(p.id) && isAdjacentToOwned(p))
        .toList();
    // cheapest (nearest ring) first, then by distance to the player
    list.sort((a, b) {
      final byPrice = a.price.compareTo(b.price);
      if (byPrice != 0) return byPrice;
      return a.centerWorld
          .distanceTo(player.position)
          .compareTo(b.centerWorld.distanceTo(player.position));
    });
    return list;
  }

  bool buyPlot(String id) {
    final plot = plots.firstWhere((p) => p.id == id);
    if (state.ownedPlots.contains(id)) return false;
    if (state.coins < plot.price) return false;
    state.coins -= plot.price;
    state.ownedPlots.add(id);
    state.touch();
    spawnResourcesForPlot(plot, density: 0.14);
    spawnAnimalsForPlot(plot, 2);
    // a few wandering enemies appear...
    for (int i = 0; i < 3; i++) {
      spawnEnemy();
    }
    // ...and a boss may be summoned when claiming new land (Forager-style)
    final bossRoll = _rng.nextDouble();
    final boss = bossRoll < 0.4
        ? EnemyKind.wraith
        : bossRoll < 0.7
            ? EnemyKind.bossSlime
            : null;
    if (boss != null) {
      spawnEnemyAt(boss, plot.centerWorld);
    }
    return true;
  }

  void restart() {
    state.reset();
    for (final c in world.children.whereType<Enemy>().toList()) {
      c.removeFromParent();
    }
    for (final c in world.children.whereType<ResourceNode>().toList()) {
      c.removeFromParent();
    }
    for (final c in world.children.whereType<DropItem>().toList()) {
      c.removeFromParent();
    }
    for (final c in world.children.whereType<Animal>().toList()) {
      c.removeFromParent();
    }
    for (final c in world.children.whereType<Building>().toList()) {
      c.removeFromParent();
    }
    for (final c in world.children.whereType<EnemyProjectile>().toList()) {
      c.removeFromParent();
    }
    _respawns.clear();
    player.position = homePlot.centerWorld;
    spawnResourcesForPlot(homePlot, density: 0.16);
    spawnAnimalsForPlot(homePlot, 3);
  }

  // ---- loop ----
  @override
  void update(double dt) {
    super.update(dt);
    if (state.gameOver) return;

    if (attackCooldown > 0) attackCooldown -= dt;
    if (hitInvuln > 0) hitInvuln -= dt;

    // combined input: keyboard + joystick
    final jin = joystick.relativeDelta;
    final combined = _keyInput + Vector2(jin.x, jin.y);
    player.input = combined.length2 > 0 ? combined : Vector2.zero();

    // respawns
    for (final rs in List<_Respawn>.from(_respawns)) {
      rs.t -= dt;
      if (rs.t <= 0) {
        _respawns.remove(rs);
        world.add(ResourceNode(rs.type, rs.pos));
      }
    }

    // enemy spawning
    if (purchasablePlots().length < plots.length) {
      enemySpawnTimer -= dt;
      if (enemySpawnTimer <= 0) {
        enemySpawnTimer = 3.5;
        if (_enemyCount < 8) spawnEnemy();
      }
    }

    // keep a small animal population on owned land
    animalSpawnTimer -= dt;
    if (animalSpawnTimer <= 0) {
      animalSpawnTimer = 9;
      final animals = world.children.whereType<Animal>().length;
      final owned = plots.where((p) => state.ownedPlots.contains(p.id)).toList();
      if (animals < 4 + owned.length && owned.isNotEmpty) {
        spawnAnimalsForPlot(owned[_rng.nextInt(owned.length)], 1);
      }
    }
  }

  // ---- input ----
  @override
  void onTapDown(TapDownInfo info) {
    doAttack();
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keys) {
    double x = 0, y = 0;
    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft)) x -= 1;
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight)) x += 1;
    if (keys.contains(LogicalKeyboardKey.keyW) ||
        keys.contains(LogicalKeyboardKey.arrowUp)) y -= 1;
    if (keys.contains(LogicalKeyboardKey.keyS) ||
        keys.contains(LogicalKeyboardKey.arrowDown)) y += 1;
    _keyInput = Vector2(x, y);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        player.tryDash();
      } else if (event.logicalKey == LogicalKeyboardKey.keyJ ||
          event.logicalKey == LogicalKeyboardKey.keyK) {
        doAttack();
      }
    }
    return KeyEventResult.handled;
  }
}
