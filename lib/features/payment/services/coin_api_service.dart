import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../models/coin_models.dart';

/// CoinApiService - Handles all coin-related API calls
/// This service communicates with the backend for coin operations
class CoinApiService {
  static final CoinApiService _instance = CoinApiService._internal();
  factory CoinApiService() => _instance;
  CoinApiService._internal();

  Dio? _dio;
  bool _isInitialized = false;

  /// Initialize the service with authentication tokens
  Future<void> initialize() async {
    if (_isInitialized && _dio != null) return;

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (accessToken != null && refreshToken != null) {
      _dio!.options.headers['cookie'] =
          'accessToken=$accessToken; refreshToken=$refreshToken';
    }

    _isInitialized = true;
    debugPrint('CoinApiService: Initialized');
  }

  /// Ensure service is initialized before making calls
  void _checkInitialized() {
    if (!_isInitialized || _dio == null) {
      throw Exception('CoinApiService not initialized. Call initialize() first.');
    }
  }

  /// Re-initialize with new tokens (call after login)
  Future<void> reinitialize() async {
    _isInitialized = false;
    _dio = null;
    await initialize();
  }

  // ============================================================
  // API METHODS
  // ============================================================

  /// Get current coin balance
  /// GET /api/v1/coins/balance
  Future<int> getBalance() async {
    _checkInitialized();

    try {
      debugPrint('CoinApiService: Fetching balance...');
      final response = await _dio!.get(ApiEndpoints.coinBalance);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final balance = response.data['data']['balance'] as int;
        debugPrint('CoinApiService: Balance = $balance');
        return balance;
      }

      throw Exception('Failed to get coin balance');
    } on DioException catch (e) {
      debugPrint('CoinApiService: Error getting balance - ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Add coins or activate a plan
  /// POST /api/v1/coins/add
  Future<AddCoinsResponse> addCoins({
    int? amount,
    String? paymentId,
    String? planId,
  }) async {
    _checkInitialized();

    try {
      debugPrint('CoinApiService: Adding coins - amount: $amount, planId: $planId');

      final Map<String, dynamic> data = {};
      if (amount != null) data['amount'] = amount;
      if (paymentId != null) data['paymentId'] = paymentId;
      if (planId != null) data['planId'] = planId;

      final response = await _dio!.post(
        ApiEndpoints.coinAdd,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          final result = AddCoinsResponse.fromJson(response.data['data']);
          debugPrint('CoinApiService: Coins added. New balance = ${result.balance}');
          return result;
        }
      }

      throw Exception(response.data['error'] ?? 'Failed to add coins');
    } on DioException catch (e) {
      debugPrint('CoinApiService: Error adding coins - ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Get coin transaction history
  /// GET /api/v1/coins/transactions?limit=&offset=
  Future<TransactionsPage> getTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    _checkInitialized();

    try {
      debugPrint('CoinApiService: Fetching transactions - limit: $limit, offset: $offset');

      final response = await _dio!.get(
        ApiEndpoints.coinTransactions,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final result = TransactionsPage.fromJson(response.data['data']);
        debugPrint('CoinApiService: Got ${result.transactions.length} transactions (total: ${result.total})');
        return result;
      }

      throw Exception('Failed to get transactions');
    } on DioException catch (e) {
      debugPrint('CoinApiService: Error getting transactions - ${e.message}');
      throw _handleDioError(e);
    }
  }

  // ============================================================
  // INSUFFICIENT COINS HANDLING
  // ============================================================

  /// Check if a Dio error is an insufficient coins error
  /// Returns InsufficientCoinsException if it is, null otherwise
  InsufficientCoinsException? checkInsufficientCoins(DioException error) {
    final response = error.response;
    if (response == null) return null;

    final data = response.data;
    if (data is! Map<String, dynamic>) return null;

    final errorCode = data['code']?.toString();
    final errorMessage = data['message']?.toString() ?? data['error']?.toString();

    if (InsufficientCoinsException.isInsufficientCoinsError(errorCode, errorMessage)) {
      final message = errorMessage ?? 'Insufficient coins';
      return InsufficientCoinsException(
        message: message,
        requiredCoins: InsufficientCoinsException.extractRequiredCoins(message),
        availableCoins: InsufficientCoinsException.extractAvailableCoins(message),
      );
    }

    return null;
  }

  /// Check any error for insufficient coins
  /// Works with both DioException and generic errors
  InsufficientCoinsException? checkAnyErrorForInsufficientCoins(dynamic error) {
    if (error is DioException) {
      return checkInsufficientCoins(error);
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('insufficient coins') ||
        errorString.contains('not enough coins')) {
      return InsufficientCoinsException(
        message: error.toString(),
        requiredCoins: InsufficientCoinsException.extractRequiredCoins(error.toString()),
        availableCoins: InsufficientCoinsException.extractAvailableCoins(error.toString()),
      );
    }

    return null;
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  Exception _handleDioError(DioException e) {
    // Check for insufficient coins first
    final insufficientCoins = checkInsufficientCoins(e);
    if (insufficientCoins != null) {
      return insufficientCoins;
    }

    // Handle other errors
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'] ?? 'Request failed';
        return Exception(message);
      }
      return Exception('Request failed with status ${e.response!.statusCode}');
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please try again.');
      case DioExceptionType.connectionError:
        return Exception('Connection error. Please check your internet.');
      default:
        return Exception(e.message ?? 'An error occurred');
    }
  }
}
