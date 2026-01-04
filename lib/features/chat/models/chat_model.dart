/// Message Type Enum
enum MessageType {
  TEXT,
  IMAGE,
  FILE,
  AUDIO;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => MessageType.TEXT,
    );
  }
}

/// User Role Enum
enum UserRole {
  CLIENT,
  ASTROLOGER,
  ADMIN;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => UserRole.CLIENT,
    );
  }
}

/// Notification Type Enum
enum NotificationType {
  CHAT_MESSAGE,
  BROADCAST_MESSAGE,
  BROADCAST_ACCEPTED,
  CONSULTATION_BOOKING,
  CONSULTATION_REMINDER,
  HOROSCOPE,
  PAYMENT,
  SYSTEM;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => NotificationType.SYSTEM,
    );
  }
}

/// Consultation Type Enum
enum ConsultationType {
  CHAT,
  VOICE,
  VIDEO;

  static ConsultationType fromString(String value) {
    return ConsultationType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => ConsultationType.CHAT,
    );
  }
}

/// Request Status Enum
enum RequestStatus {
  PENDING,
  ACCEPTED,
  CANCELLED,
  EXPIRED;

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => RequestStatus.PENDING,
    );
  }
}

/// User Model
class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? profilePhoto;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.profilePhoto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profilePhoto: json['profilePhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePhoto': profilePhoto,
    };
  }
}

/// Message Model
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;
  final UserModel? sender;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    this.metadata,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.fromString(json['type'] ?? 'TEXT'),
      metadata: json['metadata'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'metadata': metadata,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'sender': sender?.toJson(),
    };
  }
}

/// Chat Model
class ChatModel {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime? lastMessageAt;
  final bool participant1HasUnread;
  final bool participant2HasUnread;
  final DateTime createdAt;
  final UserModel? participant1;
  final UserModel? participant2;
  final MessageModel? lastMessage;

  ChatModel({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessageAt,
    required this.participant1HasUnread,
    required this.participant2HasUnread,
    required this.createdAt,
    this.participant1,
    this.participant2,
    this.lastMessage,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      participant1Id: json['participant1Id'] ?? '',
      participant2Id: json['participant2Id'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      participant1HasUnread: json['participant1HasUnread'] ?? false,
      participant2HasUnread: json['participant2HasUnread'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      participant1: json['participant1'] != null
          ? UserModel.fromJson(json['participant1'])
          : null,
      participant2: json['participant2'] != null
          ? UserModel.fromJson(json['participant2'])
          : null,
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
    );
  }
}

/// Notification Model
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final String? groupKey;
  final int? count;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.metadata,
    this.groupKey,
    this.count,
    required this.createdAt,
    this.lastUpdated,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'SYSTEM'),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
      groupKey: json['groupKey'],
      count: json['count'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }
}

/// Instant Chat Request Model
class InstantChatRequest {
  final String id;
  final String clientId;
  final String? astrologerId;
  final String? message;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final UserModel? client;
  final UserModel? acceptedAstrologer;

  InstantChatRequest({
    required this.id,
    required this.clientId,
    this.astrologerId,
    this.message,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.client,
    this.acceptedAstrologer,
  });

  factory InstantChatRequest.fromJson(Map<String, dynamic> json) {
    return InstantChatRequest(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      astrologerId: json['astrologerId'],
      message: json['message'],
      status: RequestStatus.fromString(json['status'] ?? 'PENDING'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      client: json['client'] != null
          ? UserModel.fromJson(json['client'])
          : null,
      acceptedAstrologer: json['acceptedAstrologer'] != null
          ? UserModel.fromJson(json['acceptedAstrologer'])
          : null,
    );
  }
}

/// Broadcast Message Model
class BroadcastMessage {
  final String id;
  final String clientId;
  final String content;
  final String? type;
  final RequestStatus status;
  final String? acceptedBy;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final UserModel? client;
  final UserModel? acceptedAstrologer;

  BroadcastMessage({
    required this.id,
    required this.clientId,
    required this.content,
    this.type,
    required this.status,
    this.acceptedBy,
    this.acceptedAt,
    required this.createdAt,
    this.client,
    this.acceptedAstrologer,
  });

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      content: json['content'] ?? '',
      type: json['type'],
      status: RequestStatus.fromString(json['status'] ?? 'PENDING'),
      acceptedBy: json['acceptedBy'],
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      client: json['client'] != null
          ? UserModel.fromJson(json['client'])
          : null,
      acceptedAstrologer: json['acceptedAstrologer'] != null
          ? UserModel.fromJson(json['acceptedAstrologer'])
          : null,
    );
  }
}

/// Consultation Request Model
class ConsultationRequest {
  final String id;
  final String clientId;
  final String? astrologerId;
  final ConsultationType type;
  final RequestStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final UserModel? client;
  final UserModel? acceptedAstrologer;

  ConsultationRequest({
    required this.id,
    required this.clientId,
    this.astrologerId,
    required this.type,
    required this.status,
    this.message,
    required this.createdAt,
    this.expiresAt,
    this.client,
    this.acceptedAstrologer,
  });

  factory ConsultationRequest.fromJson(Map<String, dynamic> json) {
    return ConsultationRequest(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      astrologerId: json['astrologerId'],
      type: ConsultationType.fromString(json['type'] ?? 'CHAT'),
      status: RequestStatus.fromString(json['status'] ?? 'PENDING'),
      message: json['message'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      client: json['client'] != null
          ? UserModel.fromJson(json['client'])
          : null,
      acceptedAstrologer: json['acceptedAstrologer'] != null
          ? UserModel.fromJson(json['acceptedAstrologer'])
          : null,
    );
  }
}

/// Typing Indicator Model
class TypingIndicator {
  final String senderId;
  final bool isTyping;

  TypingIndicator({required this.senderId, required this.isTyping});

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      senderId: json['senderId'] ?? '',
      isTyping: json['isTyping'] ?? false,
    );
  }
}

/// User Status Model
class UserStatusModel {
  final String userId;
  final String status; // 'online' | 'offline'

  UserStatusModel({required this.userId, required this.status});

  bool get isOnline => status == 'online';

  factory UserStatusModel.fromJson(Map<String, dynamic> json) {
    return UserStatusModel(
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'offline',
    );
  }
}
