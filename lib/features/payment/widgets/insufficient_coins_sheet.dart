import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../screens/payment_page.dart';
import '../services/coin_provider.dart';

/// Shows a bottom sheet when user has insufficient coins
/// This can be called from anywhere in the app when an INSUFFICIENT_COINS error is detected
Future<bool?> showInsufficientCoinsSheet({
  required BuildContext context,
  required int requiredCoins,
  int? availableCoins,
  String? message,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => InsufficientCoinsSheet(
      requiredCoins: requiredCoins,
      availableCoins: availableCoins ?? coinProvider.balance,
      message: message,
    ),
  );
}

class InsufficientCoinsSheet extends StatelessWidget {
  final int requiredCoins;
  final int availableCoins;
  final String? message;

  const InsufficientCoinsSheet({
    super.key,
    required this.requiredCoins,
    required this.availableCoins,
    this.message,
  });

  int get coinsNeeded => (requiredCoins - availableCoins).clamp(1, requiredCoins);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cardDark,
            AppColors.backgroundDark,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.primaryPurple.withAlpha(51),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Warning icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Insufficient Coins',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message ?? 'You need more coins to continue.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Coins breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundMedium,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withAlpha(26),
                ),
              ),
              child: Column(
                children: [
                  _buildCoinRow(
                    'Required',
                    requiredCoins,
                    Colors.white,
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _buildCoinRow(
                    'Available',
                    availableCoins,
                    availableCoins >= requiredCoins ? Colors.green : Colors.red,
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _buildCoinRow(
                    'Need to Add',
                    coinsNeeded,
                    gold,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Add Coins button
            GestureDetector(
              onTap: () => _navigateToPayment(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withAlpha(102),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Add Coins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinRow(String label, int amount, Color valueColor, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight ? gold : Colors.white70,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.monetization_on,
              color: gold,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              amount.toString(),
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToPayment(BuildContext context) {
    Navigator.pop(context, true); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentPage(),
      ),
    );
  }
}

/// Widget to display current coin balance (for use in app bar, etc.)
class CoinBalanceWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showAddButton;

  const CoinBalanceWidget({
    super.key,
    this.onTap,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coinProvider,
      builder: (context, _) {
        return GestureDetector(
          onTap: onTap ?? () => _navigateToPayment(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gold.withAlpha(51),
                  gold.withAlpha(26),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gold.withAlpha(77),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: gold,
                  size: 18,
                ),
                const SizedBox(width: 6),
                if (coinProvider.isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: gold,
                    ),
                  )
                else
                  Text(
                    coinProvider.isUnlimited ? '∞' : '${coinProvider.balance}',
                    style: const TextStyle(
                      color: gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (showAddButton) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: gold.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: gold,
                      size: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentPage(),
      ),
    );
  }
}

/// Helper function to handle insufficient coins errors
/// Call this when catching errors from chat/broadcast operations
Future<void> handleInsufficientCoinsError(
  BuildContext context,
  dynamic error, {
  VoidCallback? onRetry,
}) async {
  final insufficientCoins = coinProvider.checkInsufficientCoins(error);

  if (insufficientCoins != null) {
    final result = await showInsufficientCoinsSheet(
      context: context,
      requiredCoins: insufficientCoins.requiredCoins,
      availableCoins: insufficientCoins.availableCoins,
      message: insufficientCoins.message,
    );

    // If user added coins and wants to retry
    if (result == true && onRetry != null) {
      // Refresh balance first
      await coinProvider.refreshBalance();
      // Check if now has enough coins
      if (coinProvider.hasEnoughCoins(insufficientCoins.requiredCoins)) {
        onRetry();
      }
    }
  }
}
