import 'package:flutter/material.dart';
import '../game/audio.dart';
import '../game/building.dart';
import '../game/forager_game.dart';
import '../game/game_state.dart';

class Hud extends StatelessWidget {
  final ForagerGame game;
  const Hud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: game.state,
      builder: (context, _) {
        final s = game.state;
        return Stack(
          children: [
            // top-left stats
            Positioned(
              top: 10,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    for (int i = 0; i < s.maxHealth; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 1),
                        child: Image.asset(
                          i < s.health
                              ? 'assets/images/gui/heart_full.png'
                              : 'assets/images/gui/heart_empty.png',
                          width: 20,
                          height: 20,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  _bar(s.stamina / s.maxStamina, const Color(0xFF49d06a),
                      width: 130),
                  const SizedBox(height: 4),
                  Row(children: [
                    _bar(s.xp / s.xpToNext, const Color(0xFFf2c14e),
                        width: 100, height: 8),
                    const SizedBox(width: 6),
                    Text('Lv ${s.level}',
                        style: _txt(13, FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            // top-right coins
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xAA000000),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Image.asset('assets/images/gui/coin.png',
                      width: 18, height: 18, filterQuality: FilterQuality.none),
                  const SizedBox(width: 4),
                  Text('${s.coins}', style: _txt(15, FontWeight.bold)),
                ]),
              ),
            ),
            // inventory bottom-left
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 230),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0x88000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (s.itemOrder.isEmpty)
                      Text('Harvest with attack!',
                          style: _txt(12, FontWeight.normal)),
                    for (final id in s.itemOrder)
                      _itemChip(id, s.inventory[id] ?? 0),
                  ],
                ),
              ),
            ),
            // land shop bottom-right
            Positioned(
              right: 10,
              bottom: 110,
              child: _landShop(),
            ),
            // build menu bottom-center
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Center(child: _buildMenu()),
            ),
            // weapon quickslots top-center
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              child: Center(child: _weaponSlots()),
            ),
            // music toggle top-right (below coins)
            Positioned(
              top: 40,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  Audio.toggleMusic();
                  s.touch();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xAA000000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Audio.musicOn ? Icons.music_note : Icons.music_off,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            // controls hint
            const Positioned(
              top: 58,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'WASD move · Space dash · 1/2/3 weapon · hold J/Click to charge bow',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                ),
              ),
            ),
            if (s.gameOver) _gameOver(),
          ],
        );
      },
    );
  }

  Widget _landShop() {
    final shop = game.purchasablePlots();
    if (shop.isEmpty) return const SizedBox.shrink();
    final s = game.state;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Buy Land', style: _txt(12, FontWeight.bold)),
          const SizedBox(height: 4),
          for (final p in shop.take(5))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: GestureDetector(
                onTap: () => game.buyPlot(p.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: s.coins >= p.price
                        ? const Color(0xCC2e7d32)
                        : const Color(0x66555555),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${p.label}  ', style: _txt(11, FontWeight.w600)),
                    Image.asset('assets/images/gui/coin.png',
                        width: 12, height: 12,
                        filterQuality: FilterQuality.none),
                    Text(' ${p.price}', style: _txt(11, FontWeight.w600)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _weaponSlots() {
    const defs = [
      [Weapon.pickaxe, 'pickaxe', '1'],
      [Weapon.sword, 'sword', '2'],
      [Weapon.bow, 'bow', '3'],
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final d in defs)
            GestureDetector(
              onTap: () => game.state.setWeapon(d[0] as Weapon),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: game.state.weapon == d[0]
                      ? const Color(0xCCf2c14e)
                      : const Color(0x55ffffff),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: game.state.weapon == d[0]
                        ? Colors.white
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Image.asset('assets/images/item/${d[1]}.png',
                        width: 30,
                        height: 30,
                        filterQuality: FilterQuality.none),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text(d[2] as String, style: _txt(9, FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x77000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in BuildingType.values) _buildButton(type),
        ],
      ),
    );
  }

  Widget _buildButton(BuildingType type) {
    final cfg = buildingConfigs[type]!;
    final afford = game.canAfford(cfg.cost);
    final costStr =
        cfg.cost.entries.map((e) => '${e.value} ${e.key}').join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () => game.placeBuilding(type),
        child: Opacity(
          opacity: afford ? 1 : 0.45,
          child: Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: afford
                  ? const Color(0xCC4a3b2a)
                  : const Color(0x66333333),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x55ffffff)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/${cfg.icon}',
                    width: 26, height: 26, filterQuality: FilterQuality.none,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 26, height: 26)),
                Text(cfg.label.split(' ').first,
                    style: _txt(9, FontWeight.w600)),
                Text(costStr,
                    textAlign: TextAlign.center,
                    style: _txt(7, FontWeight.normal)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemChip(String id, int n) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0x55ffffff),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/images/item/$id.png',
            width: 24, height: 24, filterQuality: FilterQuality.none,
            errorBuilder: (_, __, ___) =>
                const SizedBox(width: 24, height: 24)),
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 3),
          child: Text('$n', style: _txt(13, FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _gameOver() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xCC000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('GAME OVER',
                  style: _txt(34, FontWeight.bold).copyWith(
                      color: const Color(0xFFff5a5a))),
              const SizedBox(height: 6),
              Text('Reached Level ${game.state.level}',
                  style: _txt(16, FontWeight.normal)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: game.restart,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2e7d32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
                child: Text('Restart', style: _txt(16, FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _bar(double frac, Color color,
      {double width = 120, double height = 12}) {
    frac = frac.clamp(0, 1);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x55ffffff), width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: frac,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _txt(double size, FontWeight w) => TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: w,
        shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
      );
}
