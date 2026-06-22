import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum ResourceType { tree, rock, berry }

class ResConfig {
  final String sprite;
  final int hp;
  final String drop;
  final int dropMin, dropMax;
  final int xp;
  const ResConfig(
      this.sprite, this.hp, this.drop, this.dropMin, this.dropMax, this.xp);
}

const _configs = {
  ResourceType.tree: ResConfig('resource/tree.png', 3, 'wood', 2, 4, 4),
  ResourceType.rock: ResConfig('resource/rock.png', 4, 'stone', 1, 3, 5),
  ResourceType.berry: ResConfig('resource/berry.png', 1, 'berry', 1, 2, 2),
};

class ResourceNode extends PositionComponent {
  final ResourceType type;
  late int hp;
  double shake = 0;
  late Sprite _sprite;
  final _rng = Random();

  ResourceNode(this.type, Vector2 worldPos) {
    position = worldPos;
    anchor = Anchor.bottomCenter;
    priority = worldPos.y.toInt();
    final cfg = _configs[type]!;
    hp = cfg.hp;
    switch (type) {
      case ResourceType.tree:
        size = Vector2(46, 70);
        break;
      case ResourceType.rock:
        size = Vector2(40, 40);
        break;
      case ResourceType.berry:
        size = Vector2(38, 38);
        break;
    }
  }

  ResConfig get cfg => _configs[type]!;

  @override
  Future<void> onLoad() async {
    final img = await Flame.images.load(cfg.sprite);
    final srcSize = type == ResourceType.tree
        ? Vector2(56, 84)
        : Vector2(56, 56);
    _sprite = Sprite(img, srcPosition: Vector2.zero(), srcSize: srcSize);
  }

  /// returns true if destroyed
  bool hit([int dmg = 1]) {
    hp -= dmg;
    shake = 0.18;
    return hp <= 0;
  }

  int rollDropCount() =>
      cfg.dropMin + _rng.nextInt(cfg.dropMax - cfg.dropMin + 1);

  @override
  void update(double dt) {
    if (shake > 0) shake -= dt;
  }

  @override
  void render(Canvas canvas) {
    final off = shake > 0 ? (sin(shake * 80) * 2.5) : 0.0;
    _sprite.render(canvas, position: Vector2(off, 0), size: size);
  }
}
