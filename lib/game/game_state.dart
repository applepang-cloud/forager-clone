import 'package:flutter/foundation.dart';

enum Weapon { pickaxe, sword, bow }

/// All player-facing stats + inventory. HUD listens to this.
class GameState extends ChangeNotifier {
  int maxHealth = 5;
  int health = 5;

  double maxStamina = 100;
  double stamina = 100;

  int level = 1;
  int xp = 0;
  int xpToNext = 20;

  int coins = 0;
  bool gameOver = false;

  Weapon weapon = Weapon.pickaxe;

  void setWeapon(Weapon w) {
    if (weapon == w) return;
    weapon = w;
    notifyListeners();
  }

  // ordered inventory
  final List<String> itemOrder = [];
  final Map<String, int> inventory = {};

  // which land plots have been bought
  final Set<String> ownedPlots = {'home'};

  void addItem(String id, int n) {
    if (!inventory.containsKey(id)) itemOrder.add(id);
    inventory[id] = (inventory[id] ?? 0) + n;
    notifyListeners();
  }

  bool spend(String id, int n) {
    final have = inventory[id] ?? 0;
    if (have < n) return false;
    inventory[id] = have - n;
    notifyListeners();
    return true;
  }

  void addCoins(int n) {
    coins += n;
    notifyListeners();
  }

  void addXp(int n, VoidCallback onLevelUp) {
    xp += n;
    while (xp >= xpToNext) {
      xp -= xpToNext;
      level++;
      xpToNext = (xpToNext * 1.35).round();
      maxHealth++;
      maxStamina += 10;
      health = maxHealth;
      stamina = maxStamina;
      onLevelUp();
    }
    notifyListeners();
  }

  void touch() => notifyListeners();

  Map<String, dynamic> toJson() => {
        'maxHealth': maxHealth,
        'health': health,
        'maxStamina': maxStamina,
        'stamina': stamina,
        'level': level,
        'xp': xp,
        'xpToNext': xpToNext,
        'coins': coins,
        'weapon': weapon.index,
        'itemOrder': itemOrder,
        'inventory': inventory,
        'ownedPlots': ownedPlots.toList(),
      };

  void fromJson(Map<String, dynamic> j) {
    maxHealth = j['maxHealth'] ?? maxHealth;
    health = j['health'] ?? health;
    maxStamina = (j['maxStamina'] ?? maxStamina).toDouble();
    stamina = (j['stamina'] ?? stamina).toDouble();
    level = j['level'] ?? level;
    xp = j['xp'] ?? xp;
    xpToNext = j['xpToNext'] ?? xpToNext;
    coins = j['coins'] ?? coins;
    weapon = Weapon.values[(j['weapon'] ?? 0).clamp(0, Weapon.values.length - 1)];
    gameOver = false;
    inventory.clear();
    itemOrder.clear();
    for (final id in (j['itemOrder'] as List? ?? [])) {
      itemOrder.add(id as String);
    }
    (j['inventory'] as Map?)?.forEach((k, v) {
      inventory[k as String] = (v as num).toInt();
    });
    ownedPlots
      ..clear()
      ..addAll(((j['ownedPlots'] as List?) ?? ['home']).cast<String>());
    if (ownedPlots.isEmpty) ownedPlots.add('home');
    notifyListeners();
  }

  void reset() {
    maxHealth = 5;
    health = 5;
    maxStamina = 100;
    stamina = 100;
    level = 1;
    xp = 0;
    xpToNext = 20;
    coins = 0;
    gameOver = false;
    weapon = Weapon.pickaxe;
    inventory.clear();
    itemOrder.clear();
    ownedPlots
      ..clear()
      ..add('home');
    notifyListeners();
  }
}
