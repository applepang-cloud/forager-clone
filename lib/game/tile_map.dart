import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'game_state.dart';
import 'world_data.dart';

/// Draws grass tiles for every owned plot. Water is the game background.
class TileMap extends Component {
  final GameState state;
  TileMap(this.state);

  late final Image _grass;
  late final List<Sprite> _variants;

  @override
  Future<void> onLoad() async {
    _grass = await Flame.images.load('tiles/grass.png');
    // grass.png is 224x56 -> four 56x56 variants
    _variants = List.generate(
      4,
      (i) => Sprite(_grass,
          srcPosition: Vector2(i * 56.0, 0), srcSize: Vector2(56, 56)),
    );
  }

  bool isLand(int c, int r) {
    for (final p in plots) {
      if (state.ownedPlots.contains(p.id) && p.contains(c, r)) return true;
    }
    return false;
  }

  // deterministic decoration: mostly plain grass, sparse subtle tufts
  int _variantFor(int c, int r) {
    final h = (c * 73856093) ^ (r * 19349663);
    final v = (h & 0x7fffffff) % 16;
    return v == 0 ? 1 : 0; // ~6% variant 1 (small tuft), rest plain
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final p in plots) {
      if (!state.ownedPlots.contains(p.id)) continue;
      for (int c = p.col; c < p.col + p.cols; c++) {
        for (int r = p.row; r < p.row + p.rows; r++) {
          _variants[_variantFor(c, r)].render(
            canvas,
            position: Vector2(c * kTile, r * kTile),
            size: Vector2(kTile, kTile),
            overridePaint: paint,
          );
        }
      }
    }
  }
}
