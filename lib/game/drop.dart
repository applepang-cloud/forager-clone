import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

/// A collectible that pops out then homes toward the player.
class DropItem extends PositionComponent {
  final String itemId;
  final Vector2 Function() playerPos;
  final void Function(String id) onCollect;

  late Sprite _sprite;
  Vector2 _vel = Vector2.zero();
  double _pop = 0.35;
  double _life = 0;
  static final _rng = Random();

  DropItem(this.itemId, Vector2 pos, this.playerPos, this.onCollect) {
    position = pos.clone();
    anchor = Anchor.center;
    size = Vector2(22, 22);
    priority = 100000;
    final a = _rng.nextDouble() * pi * 2;
    _vel = Vector2(cos(a), sin(a)) * (40 + _rng.nextDouble() * 30);
  }

  @override
  Future<void> onLoad() async {
    final img = await Flame.images.load('item/$itemId.png');
    _sprite = Sprite(img);
  }

  @override
  void update(double dt) {
    _life += dt;
    final target = playerPos();
    if (_pop > 0) {
      _pop -= dt;
      position += _vel * dt;
      _vel *= 0.88;
    } else {
      final dir = target - position;
      final d = dir.length;
      if (d < 16 && _life > 0.2) {
        onCollect(itemId);
        removeFromParent();
        return;
      }
      if (d > 0) position += dir.normalized() * 240 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    _sprite.render(canvas, size: size);
  }
}
