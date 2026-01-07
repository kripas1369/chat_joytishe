import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CoinService - Singleton
/// Manages user coin balance and paid chat sessions using local storage
class CoinService {
  static final CoinService _instance = CoinService._internal();
  factory CoinService() => _instance;
  CoinService._internal();

  static const String _coinBalanceKey = 'user_coin_balance';
  static const String _paidChatsKey = 'paid_chat_sessions';
  static const String _broadcastPaidKey = 'broadcast_session_paid';

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

  // ============================================================
  // PAID CHAT SESSION TRACKING
  // ============================================================

  /// Get list of Jothish IDs that user has already paid to chat with
  Future<List<String>> getPaidChatSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_paidChatsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('CoinService: Error decoding paid chats: $e');
      return [];
    }
  }

  /// Check if user has already paid to chat with a specific Jothish
  Future<bool> hasPaidForChat(String jothishId) async {
    final paidChats = await getPaidChatSessions();
    return paidChats.contains(jothishId);
  }

  /// Mark a Jothish chat as paid
  Future<void> markChatAsPaid(String jothishId) async {
    final prefs = await SharedPreferences.getInstance();
    final paidChats = await getPaidChatSessions();

    if (!paidChats.contains(jothishId)) {
      paidChats.add(jothishId);
      await prefs.setString(_paidChatsKey, json.encode(paidChats));
      debugPrint('CoinService: Marked chat with $jothishId as paid');
    }
  }

  /// Clear a specific paid chat session
  Future<void> clearPaidChat(String jothishId) async {
    final prefs = await SharedPreferences.getInstance();
    final paidChats = await getPaidChatSessions();

    paidChats.remove(jothishId);
    await prefs.setString(_paidChatsKey, json.encode(paidChats));
    debugPrint('CoinService: Cleared paid chat with $jothishId');
  }

  /// Clear all paid chat sessions (for new day/session)
  Future<void> clearAllPaidChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_paidChatsKey);
    debugPrint('CoinService: Cleared all paid chat sessions');
  }

  /// Pay for a chat with Jothish - deducts coin and marks as paid
  /// Returns true if successful, false if insufficient balance
  Future<bool> payForChat(String jothishId) async {
    // Check if already paid
    final alreadyPaid = await hasPaidForChat(jothishId);
    if (alreadyPaid) {
      debugPrint('CoinService: Already paid for chat with $jothishId');
      return true;
    }

    // Deduct 1 coin
    final success = await deductCoins(1);
    if (success) {
      await markChatAsPaid(jothishId);
      return true;
    }
    return false;
  }

  // ============================================================
  // BROADCAST SESSION TRACKING
  // ============================================================

  /// Check if user has paid for current broadcast session
  Future<bool> hasPaidForBroadcast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_broadcastPaidKey) ?? false;
  }

  /// Mark broadcast session as paid
  Future<void> markBroadcastAsPaid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_broadcastPaidKey, true);
    debugPrint('CoinService: Marked broadcast session as paid');
  }

  /// Clear broadcast paid status (after session ends)
  Future<void> clearBroadcastPaid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_broadcastPaidKey);
    debugPrint('CoinService: Cleared broadcast paid status');
  }

  /// Pay for broadcast - deducts 5 coins
  /// Returns true if successful, false if insufficient balance
  Future<bool> payForBroadcast() async {
    // Check if already paid for this session
    final alreadyPaid = await hasPaidForBroadcast();
    if (alreadyPaid) {
      debugPrint('CoinService: Already paid for broadcast session');
      return true;
    }

    // Deduct 5 coins
    final success = await deductCoins(5);
    if (success) {
      await markBroadcastAsPaid();
      return true;
    }
    return false;
  }
}
