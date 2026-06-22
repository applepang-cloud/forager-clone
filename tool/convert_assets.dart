// BMP -> PNG converter with color-key transparency.
// Samples the top-left corner color (and magenta) as the transparency key.
// Run: dart run tool/convert_assets.dart
import 'dart:io';
import 'package:image/image.dart' as img;

const srcRoot = r'C:\c_c\_forager_src\Images\이미지';
const dstRoot = r'C:\c_c\forager_clone\assets\images';

// source(relative to srcRoot) : destination(relative to dstRoot, without .png)
const map = <String, String>{
  // tiles
  r'타일\img_tile_plain.bmp': 'tiles/grass',
  r'타일\img_tile_plainEdge.bmp': 'tiles/grass_edge',
  r'타일\img_tile_water.bmp': 'tiles/water',
  r'타일\img_tile_wave.bmp': 'tiles/wave',
  // player
  r'플레이어\player_idle_frame.bmp': 'player/idle',
  r'플레이어\player_run_frame.bmp': 'player/run',
  r'플레이어\player_hammering_frame.bmp': 'player/hammer',
  r'플레이어\playerGotDamage.bmp': 'player/hurt',
  // enemies / npc
  r'NPC\slime_Idle2.bmp': 'enemy/slime',
  r'NPC\boss_slime.bmp': 'enemy/boss_slime',
  r'NPC\해골idle.bmp': 'enemy/skull',
  r'NPC\small_demon_idle.bmp': 'enemy/demon',
  r'NPC\황소IDLE.bmp': 'npc/cow',
  r'NPC\닭.bmp': 'npc/chicken',
  r'NPC\레이스IDLE.bmp': 'enemy/wraith',
  r'NPC\red_bullet.bmp': 'effect/bullet',
  // resources
  r'오브젝트\resource\img_object_tree.bmp': 'resource/tree',
  r'오브젝트\resource\img_object_rock.bmp': 'resource/rock',
  r'오브젝트\resource\img_object_berry.bmp': 'resource/berry',
  // buildings
  r'오브젝트\building\img_object_anvil.bmp': 'building/anvil',
  r'오브젝트\building\img_object_fishtrap.bmp': 'building/fishtrap',
  r'오브젝트\building\img_object_sewingmachine.bmp': 'building/sewingmachine',
  r'오브젝트\building\img_object_steelwork.bmp': 'building/steelwork',
  r'오브젝트\building\img_object_bridge.bmp': 'building/bridge',
  // items
  r'아이템\wood.bmp': 'item/wood',
  r'아이템\돌.bmp': 'item/stone',
  r'아이템\젤리.bmp': 'item/jelly',
  r'아이템\berry.bmp': 'item/berry',
  r'아이템\citrus.bmp': 'item/citrus',
  r'아이템\coal.bmp': 'item/coal',
  r'아이템\Iron_ore.bmp': 'item/iron_ore',
  r'아이템\Steel.bmp': 'item/steel',
  r'아이템\leather.bmp': 'item/leather',
  r'아이템\milk.bmp': 'item/milk',
  r'아이템\roast_fish.bmp': 'item/fish',
  r'아이템\brick.bmp': 'item/brick',
  r'아이템\high_class_cloth.bmp': 'item/cloth',
  r'아이템\poo.bmp': 'item/poo',
  r'아이템\섬유.bmp': 'item/fiber',
  r'아이템\sword1.bmp': 'item/sword',
  r'아이템\곡괭이1.bmp': 'item/pickaxe',
  r'아이템\bow_first.bmp': 'item/bow',
  r'아이템\arrow.bmp': 'item/arrow',
  r'아이템\skullHead.bmp': 'item/skullhead',
  // gui
  r'GUI\하트모양체력.bmp': 'gui/heart_full',
  r'GUI\하트모양체력(뒤).bmp': 'gui/heart_empty',
  r'GUI\img_UI_StaminaGaugeBar.bmp': 'gui/stamina_bar',
  r'GUI\img_UI_StaminaGaugeBoard.bmp': 'gui/stamina_board',
  r'GUI\img_UI_ExpGaugeBar.bmp': 'gui/exp_bar',
  r'GUI\img_UI_ExpGaugeBoard.bmp': 'gui/exp_board',
  r'GUI\img_game_money_icon.bmp': 'gui/coin',
  r'GUI\bag_image.bmp': 'gui/bag',
  r'GUI\img_anvil_icon.bmp': 'gui/icon_anvil',
  r'GUI\img_steelwork_icon.bmp': 'gui/icon_steelwork',
  r'GUI\img_sewingmachine_icon.bmp': 'gui/icon_sewing',
  r'GUI\img_fish_trap_icon.bmp': 'gui/icon_fishtrap',
  // effects
  r'Effects\img_effect_levelUp.bmp': 'effect/levelup',
  r'Effects\img_effect_digSmoke.bmp': 'effect/dig',
  r'Effects\img_effect_sword4.bmp': 'effect/slash',
  r'Effects\img_smoke.bmp': 'effect/smoke',
};

bool near(int a, int b, int t) => (a - b).abs() <= t;

void main() {
  var ok = 0, fail = 0;
  map.forEach((src, dst) {
    final srcPath = '$srcRoot\\${src}';
    final f = File(srcPath);
    if (!f.existsSync()) {
      stderr.writeln('MISSING: $srcPath');
      fail++;
      return;
    }
    final decoded = img.decodeBmp(f.readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('DECODE FAIL: $srcPath');
      fail++;
      return;
    }
    final im = decoded.convert(numChannels: 4);
    // Tiles are solid fills: never color-key them (corner == content color).
    final isTile = dst.startsWith('tiles/');
    if (!isTile) {
      // key color = top-left pixel
      final key = im.getPixel(0, 0);
      final kr = key.r.toInt(), kg = key.g.toInt(), kb = key.b.toInt();
      for (final p in im) {
        final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
        final isKey = near(r, kr, 12) && near(g, kg, 12) && near(b, kb, 12);
        final isMagenta = r > 230 && b > 230 && g < 40;
        if (isKey || isMagenta) p.a = 0;
      }
    }
    final outPath = '$dstRoot\\${dst.replaceAll('/', '\\')}.png';
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(img.encodePng(im));
    ok++;
  });

  // Slice the grass sheet into standalone 56x56 tiles so GPU rendering can't
  // bleed neighbouring decoration frames into a tile's edges.
  final grassBmp = File('$srcRoot\\타일\\img_tile_plain.bmp');
  if (grassBmp.existsSync()) {
    final sheet = img.decodeBmp(grassBmp.readAsBytesSync())!
        .convert(numChannels: 4);
    for (var i = 0; i < 4; i++) {
      final tile = img.copyCrop(sheet, x: i * 56, y: 0, width: 56, height: 56);
      File('$dstRoot\\tiles\\grass_$i.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(img.encodePng(tile));
    }
    stdout.writeln('Sliced grass into 4 standalone tiles');
  }

  stdout.writeln('Converted $ok, failed $fail');
}
