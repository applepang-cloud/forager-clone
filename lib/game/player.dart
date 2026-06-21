import 'package:flame/components.dart';
import 'forager_game.dart';
import 'world_data.dart';

enum PlayerState { idle, run, hammer }

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameReference<ForagerGame> {
  Vector2 input = Vector2.zero();
  Vector2 facing = Vector2(0, 1);
  double speed = 120;

  double _dash = 0; // remaining dash time
  double dashCooldown = 0;
  double attackTimer = 0;
  double hurtFlash = 0;

  Player(Vector2 pos) {
    position = pos;
    size = Vector2(40, 56);
    anchor = Anchor.bottomCenter;
  }

  @override
  Future<void> onLoad() async {
    Future<SpriteAnimation> sheet(
            String file, int amount, int perRow, double step,
            {bool loop = true}) async =>
        SpriteAnimation.fromFrameData(
          await game.images.load(file),
          SpriteAnimationData.sequenced(
            amount: amount,
            amountPerRow: perRow,
            textureSize: Vector2(40, 56),
            stepTime: step,
            loop: loop,
          ),
        );

    animations = {
      PlayerState.idle: await sheet('player/idle.png', 6, 3, 0.16),
      PlayerState.run: await sheet('player/run.png', 8, 4, 0.07),
      PlayerState.hammer: await sheet('player/hammer.png', 6, 3, 0.05),
    };
    current = PlayerState.idle;
  }

  bool get isDashing => _dash > 0;

  void tryDash() {
    if (_dash > 0 || dashCooldown > 0) return;
    if (game.state.stamina < 18) return;
    if (input.length2 == 0) return;
    _dash = 0.18;
    dashCooldown = 0.5;
    game.state.stamina -= 18;
    game.state.touch();
  }

  void attack() {
    if (attackTimer > 0) return;
    attackTimer = 0.32;
    current = PlayerState.hammer;
  }

  void hurt() {
    hurtFlash = 0.3;
  }

  bool _isLand(double x, double y) {
    final c = (x / kTile).floor();
    final r = (y / kTile).floor();
    return game.tileMap.isLand(c, r);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dashCooldown > 0) dashCooldown -= dt;
    if (_dash > 0) _dash -= dt;
    if (hurtFlash > 0) hurtFlash -= dt;

    final st = game.state;

    // stamina regen
    if (input.length2 == 0 && !isDashing) {
      st.stamina = (st.stamina + 14 * dt).clamp(0, st.maxStamina);
      st.touch();
    }

    final spd = isDashing ? speed * 2.6 : speed;
    if (input.length2 > 0) {
      final dir = input.normalized();
      facing = dir;
      // collide using the feet point (a bit above bottom anchor)
      final nx = position.x + dir.x * spd * dt;
      if (_isLand(nx, position.y - 4)) position.x = nx;
      final ny = position.y + dir.y * spd * dt;
      if (_isLand(position.x, ny - 4)) position.y = ny;
    }

    // animation state
    if (attackTimer > 0) {
      attackTimer -= dt;
      current = PlayerState.hammer;
    } else {
      current = input.length2 > 0 ? PlayerState.run : PlayerState.idle;
    }

    // facing flip
    if (facing.x.abs() > 0.05) {
      scale.x = facing.x < 0 ? -1 : 1;
    }

    priority = position.y.toInt();
  }
}
