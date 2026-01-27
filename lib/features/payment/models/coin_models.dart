/// Coin Transaction Type
enum CoinTransactionType {
  add,
  deduct,
  refund;

  static CoinTransactionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADD':
        return CoinTransactionType.add;
      case 'DEDUCT':
        return CoinTransactionType.deduct;
      case 'REFUND':
        return CoinTransactionType.refund;
      default:
        return CoinTransactionType.deduct;
    }
  }

  String toJson() {
    switch (this) {
      case CoinTransactionType.add:
        return 'ADD';
      case CoinTransactionType.deduct:
        return 'DEDUCT';
      case CoinTransactionType.refund:
        return 'REFUND';
    }
  }
}

/// Coin Transaction Reason
enum CoinTransactionReason {
  chatOrdinary,
  chatPremium,
  broadcastChat,
  paymentSuccess,
  refund,
  adminAdjustment,
  planActivation,
  other;

  static CoinTransactionReason fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CHAT_ORDINARY':
        return CoinTransactionReason.chatOrdinary;
      case 'CHAT_PREMIUM':
        return CoinTransactionReason.chatPremium;
      case 'BROADCAST_CHAT':
        return CoinTransactionReason.broadcastChat;
      case 'PAYMENT_SUCCESS':
        return CoinTransactionReason.paymentSuccess;
      case 'REFUND':
        return CoinTransactionReason.refund;
      case 'ADMIN_ADJUSTMENT':
        return CoinTransactionReason.adminAdjustment;
      case 'PLAN_ACTIVATION':
        return CoinTransactionReason.planActivation;
      default:
        return CoinTransactionReason.other;
    }
  }

  String get displayName {
    switch (this) {
      case CoinTransactionReason.chatOrdinary:
        return 'Chat Message';
      case CoinTransactionReason.chatPremium:
        return 'Premium Chat';
      case CoinTransactionReason.broadcastChat:
        return 'Broadcast Message';
      case CoinTransactionReason.paymentSuccess:
        return 'Coins Added';
      case CoinTransactionReason.refund:
        return 'Refund';
      case CoinTransactionReason.adminAdjustment:
        return 'Admin Adjustment';
      case CoinTransactionReason.planActivation:
        return 'Plan Activated';
      case CoinTransactionReason.other:
        return 'Other';
    }
  }
}

/// Model for a single coin transaction
class CoinTransaction {
  final String id;
  final String userId;
  final int amount;
  final CoinTransactionType type;
  final String reason;
  final int balanceBefore;
  final int balanceAfter;
  final String? chatId;
  final String? paymentId;
  final String? adminId;
  final DateTime createdAt;

  CoinTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.reason,
    required this.balanceBefore,
    required this.balanceAfter,
    this.chatId,
    this.paymentId,
    this.adminId,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: json['amount'] as int,
      type: CoinTransactionType.fromString(json['type'] as String),
      reason: json['reason'] as String,
      balanceBefore: json['balanceBefore'] as int,
      balanceAfter: json['balanceAfter'] as int,
      chatId: json['chatId'] as String?,
      paymentId: json['paymentId'] as String?,
      adminId: json['adminId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.toJson(),
      'reason': reason,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'chatId': chatId,
      'paymentId': paymentId,
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get the reason as a display-friendly enum
  CoinTransactionReason get reasonEnum =>
      CoinTransactionReason.fromString(reason);

  /// Check if this is a deduction
  bool get isDeduction => type == CoinTransactionType.deduct;

  /// Check if this is an addition
  bool get isAddition =>
      type == CoinTransactionType.add || type == CoinTransactionType.refund;
}

/// Response from GET /coins/transactions
class TransactionsPage {
  final List<CoinTransaction> transactions;
  final int total;

  TransactionsPage({
    required this.transactions,
    required this.total,
  });

  factory TransactionsPage.fromJson(Map<String, dynamic> json) {
    final transactionsList = (json['transactions'] as List)
        .map((t) => CoinTransaction.fromJson(t as Map<String, dynamic>))
        .toList();

    return TransactionsPage(
      transactions: transactionsList,
      total: json['total'] as int,
    );
  }

  bool get hasMore => transactions.length < total;
}

/// Response from POST /coins/add
class AddCoinsResponse {
  final String userId;
  final int balance;
  final String? transactionId;
  final bool planActivated;
  final bool isUnlimited;

  AddCoinsResponse({
    required this.userId,
    required this.balance,
    this.transactionId,
    this.planActivated = false,
    this.isUnlimited = false,
  });

  factory AddCoinsResponse.fromJson(Map<String, dynamic> json) {
    return AddCoinsResponse(
      userId: json['userId'] as String,
      balance: json['balance'] as int,
      transactionId: json['transactionId'] as String?,
      planActivated: json['planActivated'] as bool? ?? false,
      isUnlimited: json['isUnlimited'] as bool? ?? false,
    );
  }
}

/// Exception for insufficient coins
class InsufficientCoinsException implements Exception {
  final String message;
  final int requiredCoins;
  final int availableCoins;

  InsufficientCoinsException({
    required this.message,
    required this.requiredCoins,
    required this.availableCoins,
  });

  @override
  String toString() =>
      'InsufficientCoinsException: $message (Required: $requiredCoins, Available: $availableCoins)';

  /// Extract required coins from error message
  /// Looks for pattern "Required: <number>"
  static int extractRequiredCoins(String message) {
    final regex = RegExp(r'Required:\s*(\d+)');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1; // Default to 1 if not found
  }

  /// Extract available coins from error message
  /// Looks for pattern "Available: <number>" or "balance: <number>"
  static int extractAvailableCoins(String message) {
    final regex = RegExp(r'(?:Available|balance):\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }

  /// Check if an error message indicates insufficient coins
  static bool isInsufficientCoinsError(String? code, String? message) {
    if (code == 'INSUFFICIENT_COINS') return true;
    if (message == null) return false;
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('insufficient coins') ||
        lowerMessage.contains('not enough coins');
  }
}

/// Coin cost constants (for display purposes - backend enforces actual costs)
class CoinCosts {
  /// Cost per message for ORDINARY astrologers
  static const int ordinaryChat = 2;

  /// Cost per message for PROFESSIONAL astrologers
  static const int professionalChat = 2;

  /// Cost per broadcast message
  static const int broadcastMessage = 1;

  /// Premium/Katha Vachak - special rules (appointment only)
  static const int premiumChat = 0;

  /// Get cost description for display
  static String getCostDescription(String astrologerType) {
    switch (astrologerType.toUpperCase()) {
      case 'ORDINARY':
        return '$ordinaryChat coins per message';
      case 'PROFESSIONAL':
        return '$professionalChat coins per message';
      case 'PREMIUM':
      case 'KATHA_VACHAK':
        return 'Appointment only';
      default:
        return '$ordinaryChat coins per message';
    }
  }
}
