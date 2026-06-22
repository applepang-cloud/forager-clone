import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'animal.dart';
import 'enemy.dart';
import 'forager_game.dart';

/// Arrow fired by the player's bow. Hits the first enemy/animal it reaches.
class PlayerArrow extends PositionComponent with HasGameReference<ForagerGame> {
  Vector2 vel;
  final int dmg;
  double _life = 1.0;
  late Sprite _sprite;
  late double _angle;

  PlayerArrow(Vector2 pos, this.vel, this.dmg) {
    position = pos;
    anchor = Anchor.center;
    size = Vector2(26, 26);
    priority = 99998;
    _angle = atan2(vel.y, vel.x);
  }

  @override
  Future<void> onLoad() async {
    _sprite = Sprite(await game.images.load('item/arrow.png'));
  }

  @override
  void update(double dt) {
    _life -= dt;
    position += vel * dt;
    final c = (position.x / 48).floor();
    final r = (position.y / 48).floor();
    if (_life <= 0 || !game.tileMap.isLand(c, r)) {
      removeFromParent();
      return;
    }
    for (final e in game.world.children.whereType<Enemy>()) {
      if (e.position.distanceTo(position) < 24) {
        e.takeHit(dmg, position);
        removeFromParent();
        return;
      }
    }
    for (final a in game.world.children.whereType<Animal>().toList()) {
      if (a.position.distanceTo(position) < 22) {
        game.harvestAnimal(a);
        removeFromParent();
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_angle);
    canvas.translate(-size.x / 2, -size.y / 2);
    _sprite.render(canvas, size: size);
    canvas.restore();
  }
}
