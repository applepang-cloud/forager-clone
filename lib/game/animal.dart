import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'forager_game.dart';

enum AnimalKind { cow, chicken }

class AnimalConfig {
  final String sprite;
  final Vector2 src, srcSize, renderSize;
  final int hp;
  final List<String> drops;
  final int xp;
  const AnimalConfig(this.sprite, this.src, this.srcSize, this.renderSize,
      this.hp, this.drops, this.xp);
}

final animalConfigs = {
  AnimalKind.cow: AnimalConfig('npc/cow.png', Vector2(2, 2), Vector2(76, 46),
      Vector2(52, 32), 3, ['milk', 'leather'], 4),
  AnimalKind.chicken: AnimalConfig('npc/chicken.png', Vector2(1, 1),
      Vector2(18, 27), Vector2(28, 26), 1, ['poo'], 2),
};

/// Passive wandering critter. Hit it to harvest drops; it flees when struck.
class Animal extends PositionComponent with HasGameReference<ForagerGame> {
  final AnimalKind kind;
  late int hp;
  late AnimalConfig cfg;
  late Sprite _sprite;

  Vector2 _wander = Vector2.zero();
  double _wanderTimer = 0;
  double _flee = 0;
  double _hitFlash = 0;
  double _bob = 0;
  int _facing = 1;
  final _rng = Random();

  Animal(this.kind, Vector2 pos) {
    position = pos;
    anchor = Anchor.bottomCenter;
    cfg = animalConfigs[kind]!;
    hp = cfg.hp;
    size = cfg.renderSize.clone();
  }

  @override
  Future<void> onLoad() async {
    _sprite = Sprite(await game.images.load(cfg.sprite),
        srcPosition: cfg.src, srcSize: cfg.srcSize);
  }

  /// returns true if killed (harvested)
  bool takeHit() {
    hp--;
    _hitFlash = 0.16;
    _flee = 1.6;
    return hp <= 0;
  }

  @override
  void update(double dt) {
    _bob += dt * 8;
    if (_hitFlash > 0) _hitFlash -= dt;

    Vector2 move;
    if (_flee > 0) {
      _flee -= dt;
      move = (position - game.player.position);
      if (move.length2 > 0) move = move.normalized();
    } else {
      _wanderTimer -= dt;
      if (_wanderTimer <= 0) {
        _wanderTimer = 1.5 + _rng.nextDouble() * 2.5;
        if (_rng.nextDouble() < 0.4) {
          _wander = Vector2.zero();
        } else {
          final a = _rng.nextDouble() * pi * 2;
          _wander = Vector2(cos(a), sin(a));
        }
      }
      move = _wander;
    }

    final speed = _flee > 0 ? 90.0 : 32.0;
    final next = position + move * speed * dt;
    final c = (next.x / 48).floor();
    final r = ((next.y - 4) / 48).floor();
    if (game.tileMap.isLand(c, r)) position = next;
    if (move.x.abs() > 0.05) _facing = move.x < 0 ? -1 : 1;

    priority = position.y.toInt();
  }

  @override
  void render(Canvas canvas) {
    final dy = sin(_bob) * 1.5;
    canvas.save();
    if (_facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    final paint = _hitFlash > 0
        ? (Paint()
          ..colorFilter =
              const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcATop))
        : null;
    _sprite.render(canvas,
        position: Vector2(0, dy), size: size, overridePaint: paint);
    canvas.restore();
  }
}
