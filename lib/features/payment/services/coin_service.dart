import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CoinService - Singleton
/// Manages user coin balance using local storage
class CoinService {
  static final CoinService _instance = CoinService._internal();
  factory CoinService() => _instance;
  CoinService._internal();

  static const String _coinBalanceKey = 'user_coin_balance';

  /// Get current coin balance
  Future<int> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_coinBalanceKey) ?? 0;
  }

  /// Add coins to balance
  Future<int> addCoins(int amount) async {
    if (amount <= 0) return await getBalance();

    final prefs = await SharedPreferences.getInstance();
    final currentBalance = prefs.getInt(_coinBalanceKey) ?? 0;
    final newBalance = currentBalance + amount;
    await prefs.setInt(_coinBalanceKey, newBalance);
    debugPrint('CoinService: Added $amount coins. New balance: $newBalance');
    return newBalance;
  }

  /// Deduct coins from balance
  /// Returns true if deduction successful, false if insufficient balance
  Future<bool> deductCoins(int amount) async {
    if (amount <= 0) return true;

    final prefs = await SharedPreferences.getInstance();
    final currentBalance = prefs.getInt(_coinBalanceKey) ?? 0;

    if (currentBalance < amount) {
      debugPrint('CoinService: Insufficient balance. Current: $currentBalance, Required: $amount');
      return false;
    }

    final newBalance = currentBalance - amount;
    await prefs.setInt(_coinBalanceKey, newBalance);
    debugPrint('CoinService: Deducted $amount coins. New balance: $newBalance');
    return true;
  }

  /// Check if user has enough coins
  Future<bool> hasEnoughCoins(int amount) async {
    final balance = await getBalance();
    return balance >= amount;
  }

  /// Set balance directly (for testing or admin purposes)
  Future<void> setBalance(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinBalanceKey, balance);
    debugPrint('CoinService: Balance set to $balance');
  }

  /// Clear coin balance
  Future<void> clearBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coinBalanceKey);
    debugPrint('CoinService: Balance cleared');
  }
}
