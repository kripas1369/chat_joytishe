/// Coin System - Complete coin management for the app
///
/// This file exports all coin-related classes and functions.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:chat_jyotishi/features/payment/coin_system.dart';
///
/// // Initialize on app start (e.g., after login)
/// await coinProvider.initialize();
///
/// // Get current balance
/// final balance = coinProvider.balance;
///
/// // Listen to balance changes
/// coinProvider.addListener(() {
///   print('Balance changed: ${coinProvider.balance}');
/// });
///
/// // Add coins via API
/// final response = await coinProvider.addCoins(amount: 10, paymentId: 'xyz');
///
/// // Handle insufficient coins
/// try {
///   // your code
/// } catch (e) {
///   await handleInsufficientCoinsError(context, e);
/// }
/// ```
///
/// ## Components
///
/// - [CoinProvider] - Global state management for coin balance
/// - [CoinApiService] - API calls to backend
/// - [CoinTransaction] - Transaction model
/// - [InsufficientCoinsException] - Exception for insufficient coins
/// - [showInsufficientCoinsSheet] - Bottom sheet for purchasing coins
/// - [CoinBalanceWidget] - Widget to display balance in app bar

// Models
export 'models/coin_models.dart';

// Services
export 'services/coin_api_service.dart';
export 'services/coin_provider.dart';
export 'services/coin_service.dart'; // Legacy local storage service

// Widgets
export 'widgets/insufficient_coins_sheet.dart';

// Screens
export 'screens/payment_page.dart';
