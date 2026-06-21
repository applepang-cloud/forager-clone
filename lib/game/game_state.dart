import 'package:flutter/foundation.dart';

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
    inventory.clear();
    itemOrder.clear();
    ownedPlots
      ..clear()
      ..add('home');
    notifyListeners();
  }
}
