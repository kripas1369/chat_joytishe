import 'dart:async';
import 'package:flutter/foundation.dart';
import 'coin_api_service.dart';
import '../models/coin_models.dart';

/// CoinProvider - Global state management for coin balance
/// This is a ChangeNotifier that can be used with Provider or listened to directly
class CoinProvider extends ChangeNotifier {
  static final CoinProvider _instance = CoinProvider._internal();
  factory CoinProvider() => _instance;
  CoinProvider._internal();

  final CoinApiService _apiService = CoinApiService();

  // State
  int _balance = 0;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  bool _isUnlimited = false;

  // Getters
  int get balance => _balance;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isUnlimited => _isUnlimited;
  bool get hasCoins => _balance > 0 || _isUnlimited;

  /// Stream controller for balance updates
  final _balanceController = StreamController<int>.broadcast();
  Stream<int> get balanceStream => _balanceController.stream;

  /// Initialize the provider and fetch initial balance
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.initialize();
      await refreshBalance();

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('CoinProvider: Initialization error - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh balance from server
  Future<int> refreshBalance() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final balance = await _apiService.getBalance();
      _balance = balance;
      _balanceController.add(_balance);

      debugPrint('CoinProvider: Balance refreshed = $_balance');
      return _balance;
    } catch (e) {
      _error = e.toString();
      debugPrint('CoinProvider: Error refreshing balance - $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add coins via API
  Future<AddCoinsResponse> addCoins({
    int? amount,
    String? paymentId,
    String? planId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.addCoins(
        amount: amount,
        paymentId: paymentId,
        planId: planId,
      );

      // Update local state from response
      _balance = response.balance;
      _isUnlimited = response.isUnlimited;
      _balanceController.add(_balance);

      debugPrint('CoinProvider: Coins added. New balance = $_balance');
      return response;
    } catch (e) {
      _error = e.toString();
      debugPrint('CoinProvider: Error adding coins - $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get transaction history
  Future<TransactionsPage> getTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _apiService.getTransactions(
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('CoinProvider: Error getting transactions - $e');
      rethrow;
    }
  }

  /// Update balance locally (after a deduction from chat/broadcast)
  /// Use this to immediately reflect deductions without waiting for API
  void localDeduct(int amount) {
    if (amount <= 0) return;
    _balance = (_balance - amount).clamp(0, _balance);
    _balanceController.add(_balance);
    notifyListeners();
    debugPrint('CoinProvider: Local deduction of $amount. New balance = $_balance');
  }

  /// Update balance locally (after adding coins)
  void localAdd(int amount) {
    if (amount <= 0) return;
    _balance += amount;
    _balanceController.add(_balance);
    notifyListeners();
    debugPrint('CoinProvider: Local addition of $amount. New balance = $_balance');
  }

  /// Set balance directly (use sparingly)
  void setBalance(int balance) {
    _balance = balance;
    _balanceController.add(_balance);
    notifyListeners();
  }

  /// Check if user has enough coins
  bool hasEnoughCoins(int required) {
    return _isUnlimited || _balance >= required;
  }

  /// Check error for insufficient coins
  InsufficientCoinsException? checkInsufficientCoins(dynamic error) {
    return _apiService.checkAnyErrorForInsufficientCoins(error);
  }

  /// Clear state (call on logout)
  void clear() {
    _balance = 0;
    _isLoading = false;
    _isInitialized = false;
    _error = null;
    _isUnlimited = false;
    _balanceController.add(_balance);
    notifyListeners();
    debugPrint('CoinProvider: State cleared');
  }

  /// Re-initialize after login
  Future<void> reinitialize() async {
    _isInitialized = false;
    await _apiService.reinitialize();
    await initialize();
  }

  @override
  void dispose() {
    _balanceController.close();
    super.dispose();
  }
}

/// Global instance for easy access
final coinProvider = CoinProvider();
