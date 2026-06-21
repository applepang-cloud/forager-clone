# Forager Clone (Flutter / Flame)

A Flutter port of the WinAPI C++ game **[copolio/Forager-Clone](https://github.com/copolio/Forager-Clone)**,
itself a demo-scale clone of HopFrog's *Forager*. Built with the [Flame](https://flame-engine.org) engine,
reusing the original project's sprite art (BMP → PNG converted).

## Gameplay
- **Move**: WASD / arrow keys, or the on-screen joystick (mobile).
- **Dash**: Space (or the green button) — costs stamina.
- **Attack / Harvest**: J / K / mouse-click, or the red button. Hits the nearest
  resource and any enemies in range.
- Harvest **trees → wood**, **rocks → stone (+ coal/iron)**, **berry bushes → berry**.
- **Stamina** drains on actions; when empty you lose a heart and it refills.
- **XP** from harvesting & kills; leveling up raises max HP/stamina and fully heals.
- **Slimes / skulls** wander and chase you on purchased land; kill them for coins + jelly.
- **Buy Land** (bottom-right shop) with coins to expand the island — bigger world,
  more resources, and enemy spawns.

## Assets
Original BMP sprites live in `C:\c_c\_forager_src` (the cloned repo). They are converted
to color-keyed PNGs by `tool/convert_assets.dart`:

```
dart run tool/convert_assets.dart
```

Output goes to `assets/images/{tiles,player,enemy,resource,item,gui,...}`.

## Run
```
flutter run -d chrome          # or any device
flutter test                   # smoke + offscreen-render checks
flutter build web --release --no-web-resources-cdn   # bundles canvaskit locally
```

## Project layout
- `lib/game/forager_game.dart` — main `FlameGame`: input, spawning, combat, land purchase.
- `lib/game/player.dart` — movement, dash, stamina, animation states.
- `lib/game/resource_node.dart`, `enemy.dart`, `drop.dart` — world entities.
- `lib/game/tile_map.dart`, `world_data.dart` — island tiles & purchasable plots.
- `lib/game/game_state.dart` — stats/inventory (`ChangeNotifier`).
- `lib/ui/hud.dart` — Flutter overlay: hearts, stamina/XP bars, coins, inventory, land shop.
