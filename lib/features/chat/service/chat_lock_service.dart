import 'package:shared_preferences/shared_preferences.dart';

/// Chat Lock Service - Singleton
/// Manages the global chat lock state across all Jyotish chats
class ChatLockService {
  static final ChatLockService _instance = ChatLockService._internal();
  factory ChatLockService() => _instance;
  ChatLockService._internal();

  // Keys for SharedPreferences
  static const String _isLockedKey = 'chat_is_locked';
  static const String _lockedJyotishIdKey = 'chat_locked_jyotish_id';
  static const String _lockedJyotishNameKey = 'chat_locked_jyotish_name';
  static const String _messageSentAtKey = 'chat_message_sent_at';
  static const String _waitingTimeoutMinutesKey = 'chat_waiting_timeout';
  static const String _hasUserSentMessageKey = 'chat_has_user_sent_message';

  // Default timeout in minutes before showing inquiry option
  static const int defaultTimeoutMinutes = 5;

  /// Check if chat is currently locked
  Future<bool> isLocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLockedKey) ?? false;
  }

  /// Get the Jyotish ID that user is waiting for reply from
  Future<String?> getLockedJyotishId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockedJyotishIdKey);
  }

  /// Get the timestamp when message was sent
  Future<DateTime?> getMessageSentAt() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_messageSentAtKey);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Get the Jyotish name that user is waiting for reply from
  Future<String?> getLockedJyotishName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockedJyotishNameKey);
  }

  /// Check if user has already sent a message (before lock)
  Future<bool> hasUserSentMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasUserSentMessageKey) ?? false;
  }

  /// Lock all chats after user sends a message
  /// [jyotishId] - The Jyotish ID that user is waiting for reply from
  /// [jyotishName] - The Jyotish name for display purposes
  Future<void> lockChats(String jyotishId, {String? jyotishName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLockedKey, true);
    await prefs.setString(_lockedJyotishIdKey, jyotishId);
    if (jyotishName != null) {
      await prefs.setString(_lockedJyotishNameKey, jyotishName);
    }
    await prefs.setString(_messageSentAtKey, DateTime.now().toIso8601String());
    await prefs.setBool(_hasUserSentMessageKey, true);
  }

  /// Unlock all chats when Jyotish replies
  Future<void> unlockChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLockedKey, false);
    await prefs.remove(_lockedJyotishIdKey);
    await prefs.remove(_lockedJyotishNameKey);
    await prefs.remove(_messageSentAtKey);
    await prefs.setBool(_hasUserSentMessageKey, false);
  }

  /// Check if the reply is from the locked Jyotish
  Future<bool> isReplyFromLockedJyotish(String jyotishId) async {
    final lockedId = await getLockedJyotishId();
    return lockedId == jyotishId;
  }

  /// Check if waiting time has exceeded timeout
  Future<bool> hasExceededTimeout() async {
    final sentAt = await getMessageSentAt();
    if (sentAt == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final timeoutMinutes = prefs.getInt(_waitingTimeoutMinutesKey) ?? defaultTimeoutMinutes;

    final now = DateTime.now();
    final difference = now.difference(sentAt).inMinutes;
    return difference >= timeoutMinutes;
  }

  /// Get remaining time before timeout in seconds
  Future<int> getRemainingTimeSeconds() async {
    final sentAt = await getMessageSentAt();
    if (sentAt == null) return 0;

    final prefs = await SharedPreferences.getInstance();
    final timeoutMinutes = prefs.getInt(_waitingTimeoutMinutesKey) ?? defaultTimeoutMinutes;

    final now = DateTime.now();
    final difference = now.difference(sentAt).inSeconds;
    final totalTimeoutSeconds = timeoutMinutes * 60;

    return (totalTimeoutSeconds - difference).clamp(0, totalTimeoutSeconds);
  }

  /// Check if user can send message to a specific Jyotish
  /// Returns true only if:
  /// - Chats are not locked, OR
  /// - This is the same Jyotish user is waiting for (they replied)
  Future<bool> canSendMessage(String jyotishId) async {
    final locked = await isLocked();
    if (!locked) return true;

    // If locked, can only interact with the same Jyotish
    final lockedId = await getLockedJyotishId();
    return lockedId == jyotishId;
  }

  /// Get lock status details
  Future<Map<String, dynamic>> getLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLocked': prefs.getBool(_isLockedKey) ?? false,
      'lockedJyotishId': prefs.getString(_lockedJyotishIdKey),
      'lockedJyotishName': prefs.getString(_lockedJyotishNameKey),
      'messageSentAt': prefs.getString(_messageSentAtKey),
      'hasUserSentMessage': prefs.getBool(_hasUserSentMessageKey) ?? false,
      'hasExceededTimeout': await hasExceededTimeout(),
      'remainingSeconds': await getRemainingTimeSeconds(),
    };
  }

  /// Check if user can send a message to a specific Jyotish in current session
  /// Returns false if user has already sent a message and is waiting for reply
  Future<bool> canSendMessageInChat(String jyotishId) async {
    final locked = await isLocked();
    if (!locked) {
      // Not locked - user hasn't sent any message yet, can send
      return true;
    }

    // If locked, check if this is the same Jyotish user sent to
    final lockedId = await getLockedJyotishId();
    if (lockedId != jyotishId) {
      // Different Jyotish - cannot send
      return false;
    }

    // Same Jyotish - user already sent message, cannot send more
    // (waiting for reply)
    return false;
  }
}
