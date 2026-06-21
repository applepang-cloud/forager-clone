import 'dart:ui';
import 'package:flame/components.dart';
import 'forager_game.dart';

enum BuildingType { fishtrap, anvil, steelwork, sewing }

class BuildingConfig {
  final String label;
  final String sprite;
  final String icon;
  final Vector2 src, srcSize, renderSize;
  final Map<String, int> cost;
  final Map<String, int> input;
  final String output;
  final double interval;
  const BuildingConfig(this.label, this.sprite, this.icon, this.src,
      this.srcSize, this.renderSize, this.cost, this.input, this.output,
      this.interval);
}

final buildingConfigs = {
  BuildingType.fishtrap: BuildingConfig(
    'Fish Trap',
    'building/fishtrap.png',
    'gui/icon_fishtrap.png',
    Vector2(0, 0),
    Vector2(56, 56),
    Vector2(40, 40),
    {'wood': 3},
    {}, // no input: produces fish from the sea
    'fish',
    6,
  ),
  BuildingType.anvil: BuildingConfig(
    'Anvil',
    'building/anvil.png',
    'gui/icon_anvil.png',
    Vector2(0, 0),
    Vector2(95, 95),
    Vector2(54, 46),
    {'wood': 3, 'stone': 3},
    {'stone': 2},
    'brick',
    4,
  ),
  BuildingType.steelwork: BuildingConfig(
    'Steelwork',
    'building/steelwork.png',
    'gui/icon_steelwork.png',
    Vector2(0, 0),
    Vector2(168, 168),
    Vector2(60, 60),
    {'wood': 5, 'stone': 5},
    {'coal': 1, 'iron_ore': 1},
    'steel',
    5,
  ),
  BuildingType.sewing: BuildingConfig(
    'Sewing Machine',
    'building/sewingmachine.png',
    'gui/icon_sewing.png',
    Vector2(0, 0),
    Vector2(189, 155),
    Vector2(58, 48),
    {'wood': 4},
    {'leather': 1},
    'cloth',
    5,
  ),
};

class Building extends PositionComponent with HasGameReference<ForagerGame> {
  final BuildingType type;
  late BuildingConfig cfg;
  late Sprite _sprite;
  double _timer = 0;
  double _progress = 0;

  Building(this.type, Vector2 pos) {
    position = pos;
    anchor = Anchor.bottomCenter;
    cfg = buildingConfigs[type]!;
    size = cfg.renderSize.clone();
  }

  @override
  Future<void> onLoad() async {
    _sprite = Sprite(await game.images.load(cfg.sprite),
        srcPosition: cfg.src, srcSize: cfg.srcSize);
  }

  @override
  void update(double dt) {
    _timer += dt;
    _progress = (_timer / cfg.interval).clamp(0, 1);
    if (_timer >= cfg.interval) {
      _timer = 0;
      // check inputs
      final inv = game.state.inventory;
      var ok = true;
      cfg.input.forEach((k, v) {
        if ((inv[k] ?? 0) < v) ok = false;
      });
      if (ok) {
        cfg.input.forEach((k, v) => game.state.spend(k, v));
        game.state.addItem(cfg.output, 1);
      }
    }
    priority = position.y.toInt();
  }

  @override
  void render(Canvas canvas) {
    _sprite.render(canvas, size: size);
    // production progress bar
    canvas.drawRect(Rect.fromLTWH(2, -6, size.x - 4, 3),
        Paint()..color = const Color(0x88000000));
    canvas.drawRect(Rect.fromLTWH(2, -6, (size.x - 4) * _progress, 3),
        Paint()..color = const Color(0xFF6fd16f));
  }
}
