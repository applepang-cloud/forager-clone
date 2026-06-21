import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'forager_game.dart';

enum EnemyKind { slime, skull, bossSlime, wraith }

class EnemyConfig {
  final String sprite;
  final Vector2 src, srcSize, renderSize;
  final int hp;
  final double speed;
  final int touchDamage;
  final int coins, xp;
  const EnemyConfig(this.sprite, this.src, this.srcSize, this.renderSize,
      this.hp, this.speed, this.touchDamage, this.coins, this.xp);
}

final enemyConfigs = {
  EnemyKind.slime: EnemyConfig('enemy/slime.png', Vector2(3, 3),
      Vector2(50, 64), Vector2(42, 34), 3, 42, 1, 2, 5),
  EnemyKind.skull: EnemyConfig('enemy/skull.png', Vector2(4, 4),
      Vector2(48, 56), Vector2(40, 44), 5, 70, 1, 4, 9),
  EnemyKind.bossSlime: EnemyConfig('enemy/boss_slime.png', Vector2(2, 2),
      Vector2(108, 108), Vector2(86, 70), 30, 34, 2, 25, 60),
  EnemyKind.wraith: EnemyConfig('enemy/wraith.png', Vector2(8, 8),
      Vector2(272, 176), Vector2(70, 48), 22, 46, 1, 30, 70),
};

class Enemy extends PositionComponent with HasGameReference<ForagerGame> {
  final EnemyKind kind;
  late int hp;
  late int maxHp;
  late Sprite _sprite;
  late EnemyConfig cfg;

  Vector2 _wander = Vector2.zero();
  double _wanderTimer = 0;
  double _bob = 0;
  double _hitFlash = 0;
  double _castTimer = 2;
  double _shootTimer = 1.5;
  Vector2 _knock = Vector2.zero();
  final _rng = Random();

  Enemy(this.kind, Vector2 pos) {
    position = pos;
    anchor = Anchor.bottomCenter;
    cfg = enemyConfigs[kind]!;
    hp = cfg.hp;
    maxHp = cfg.hp;
    size = cfg.renderSize.clone();
  }

  bool get isBoss => kind == EnemyKind.bossSlime || kind == EnemyKind.wraith;

  @override
  Future<void> onLoad() async {
    final img = await game.images.load(cfg.sprite);
    _sprite = Sprite(img, srcPosition: cfg.src, srcSize: cfg.srcSize);
  }

  void takeHit(int dmg, Vector2 from) {
    hp -= dmg;
    _hitFlash = 0.18;
    final dir = (position - from);
    if (dir.length2 > 0) _knock = dir.normalized() * (isBoss ? 40 : 120);
  }

  @override
  void update(double dt) {
    _bob += dt * 6;
    if (_hitFlash > 0) _hitFlash -= dt;
    if (hp <= 0) {
      game.onEnemyKilled(this);
      removeFromParent();
      return;
    }

    final playerPos = game.player.position;
    final toPlayer = playerPos - position;
    final dist = toPlayer.length;

    Vector2 move = Vector2.zero();
    switch (kind) {
      case EnemyKind.wraith:
        // hover at range, summon skulls and shoot bullets
        if (dist < 150) {
          move = -toPlayer.normalized(); // back away
        } else if (dist > 240) {
          move = toPlayer.normalized();
        } else {
          _wanderTimer -= dt;
          if (_wanderTimer <= 0) {
            _wanderTimer = 0.8 + _rng.nextDouble();
            final a = _rng.nextDouble() * pi * 2;
            _wander = Vector2(cos(a), sin(a)) * 0.5;
          }
          move = _wander;
        }
        _castTimer -= dt;
        if (_castTimer <= 0) {
          _castTimer = 4.5;
          game.spawnEnemyAt(EnemyKind.skull, position + Vector2(0, -20));
        }
        _shootTimer -= dt;
        if (_shootTimer <= 0 && dist < 320) {
          _shootTimer = 1.8;
          game.spawnEnemyBullet(position, playerPos);
        }
        break;
      case EnemyKind.bossSlime:
        move = dist < 360 ? toPlayer.normalized() : _doWander(dt);
        break;
      default:
        move = dist < 220 ? toPlayer.normalized() : _doWander(dt);
    }

    final next = position + move * cfg.speed * dt + _knock * dt;
    _knock *= 0.85;
    final c = (next.x / 48).floor();
    final r = ((next.y - 4) / 48).floor();
    if (game.tileMap.isLand(c, r)) position = next;

    // contact damage (melee kinds)
    if (kind != EnemyKind.wraith && dist < (isBoss ? 40 : 26)) {
      game.enemyTouch(cfg.touchDamage);
    }

    priority = position.y.toInt();
  }

  Vector2 _doWander(double dt) {
    _wanderTimer -= dt;
    if (_wanderTimer <= 0) {
      _wanderTimer = 1 + _rng.nextDouble() * 2;
      final a = _rng.nextDouble() * pi * 2;
      _wander = Vector2(cos(a), sin(a));
    }
    return _wander;
  }

  @override
  void render(Canvas canvas) {
    final dy = sin(_bob) * 2;
    final paint = _hitFlash > 0
        ? (Paint()
          ..colorFilter =
              const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcATop))
        : null;
    _sprite.render(canvas,
        position: Vector2(0, dy), size: size, overridePaint: paint);

    // boss health bar
    if (isBoss && hp < maxHp) {
      final w = size.x;
      canvas.drawRect(Rect.fromLTWH(0, -8, w, 4),
          Paint()..color = const Color(0xAA000000));
      canvas.drawRect(Rect.fromLTWH(0, -8, w * (hp / maxHp), 4),
          Paint()..color = const Color(0xFFff4444));
    }
  }
}

/// A bullet fired by a wraith toward the player.
class EnemyProjectile extends PositionComponent
    with HasGameReference<ForagerGame> {
  Vector2 vel;
  double _life = 4;
  late Sprite _sprite;
  EnemyProjectile(Vector2 pos, this.vel) {
    position = pos;
    anchor = Anchor.center;
    size = Vector2(18, 18);
    priority = 99999;
  }

  @override
  Future<void> onLoad() async {
    _sprite = Sprite(await game.images.load('effect/bullet.png'));
  }

  @override
  void update(double dt) {
    _life -= dt;
    position += vel * dt;
    if (position.distanceTo(game.player.position) < 20) {
      game.enemyTouch(1);
      removeFromParent();
      return;
    }
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) => _sprite.render(canvas, size: size);
}
