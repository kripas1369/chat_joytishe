/// Astrologer Chat Models
/// All data models for astrologer chat functionality
library;

// ============================================================
// ENUMS
// ============================================================

enum AstrologerType {
  ORDINARY,
  PROFESSIONAL,
  PREMIUM;

  static AstrologerType fromString(String value) {
    return AstrologerType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => AstrologerType.ORDINARY,
    );
  }
}

enum BroadcastStatus {
  PENDING,
  ACCEPTED,
  EXPIRED,
  DISMISSED;

  static BroadcastStatus fromString(String value) {
    return BroadcastStatus.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => BroadcastStatus.PENDING,
    );
  }
}

enum InstantChatStatus {
  PENDING,
  ACCEPTED,
  REJECTED,
  EXPIRED;

  static InstantChatStatus fromString(String value) {
    return InstantChatStatus.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => InstantChatStatus.PENDING,
    );
  }
}

// ============================================================
// USER MODELS
// ============================================================

/// Basic user info for chat participants
class ChatUserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? profilePhoto;
  final String? role;

  ChatUserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.profilePhoto,
    this.role,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profilePhoto: json['profilePhoto'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'role': role,
    };
  }
}

/// Client profile with birth details for astrologer consultation
class ClientProfileModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? profilePhoto;
  final DateTime? birthDate;
  final String? birthTime;
  final String? birthPlace;
  final String? zodiacSign;
  final String? gender;
  final List<AddressModel>? addresses;
  final Map<String, dynamic>? additionalInfo;
  final DateTime? createdAt;

  ClientProfileModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.profilePhoto,
    this.birthDate,
    this.birthTime,
    this.birthPlace,
    this.zodiacSign,
    this.gender,
    this.addresses,
    this.additionalInfo,
    this.createdAt,
  });

  factory ClientProfileModel.fromJson(Map<String, dynamic> json) {
    List<AddressModel>? addresses;
    if (json['addresses'] != null) {
      addresses = (json['addresses'] as List)
          .map((a) => AddressModel.fromJson(a))
          .toList();
    }

    return ClientProfileModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profilePhoto: json['profilePhoto'],
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'])
          : null,
      birthTime: json['birthTime'],
      birthPlace: json['birthPlace'],
      zodiacSign: json['zodiacSign'],
      gender: json['gender'],
      addresses: addresses,
      additionalInfo: json['additionalInfo'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

/// Address model
class AddressModel {
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final bool? isDefault;

  AddressModel({
    this.street,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
      isDefault: json['isDefault'],
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }
}

/// Chatable user for listing clients
class ChatableUserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? profilePhoto;
  final String? role;
  final bool? isOnline;
  final DateTime? lastSeen;

  ChatableUserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.profilePhoto,
    this.role,
    this.isOnline,
    this.lastSeen,
  });

  factory ChatableUserModel.fromJson(Map<String, dynamic> json) {
    return ChatableUserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profilePhoto: json['profilePhoto'],
      role: json['role'],
      isOnline: json['isOnline'],
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'])
          : null,
    );
  }
}

// ============================================================
// CONVERSATION MODEL
// ============================================================

class ConversationModel {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final ChatUserModel? participant1;
  final ChatUserModel? participant2;
  final MessagePreviewModel? lastMessage;
  final DateTime? lastMessageAt;
  final bool participant1HasUnread;
  final bool participant2HasUnread;
  final int? unreadCount;
  final String? status;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.participant1,
    this.participant2,
    this.lastMessage,
    this.lastMessageAt,
    this.participant1HasUnread = false,
    this.participant2HasUnread = false,
    this.unreadCount,
    this.status,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Handle different API response formats

    // Format 1: participant1, participant2 structure
    ChatUserModel? p1 = json['participant1'] != null
        ? ChatUserModel.fromJson(json['participant1'])
        : null;
    ChatUserModel? p2 = json['participant2'] != null
        ? ChatUserModel.fromJson(json['participant2'])
        : null;

    // Format 2: clientParticipant / astrologerParticipant structure
    if (p1 == null && json['clientParticipant'] != null) {
      p1 = ChatUserModel.fromJson(json['clientParticipant']);
    }
    if (p2 == null && json['astrologerParticipant'] != null) {
      p2 = ChatUserModel.fromJson(json['astrologerParticipant']);
    }

    // Format 3: client / astrologer structure
    if (p1 == null && json['client'] != null) {
      p1 = ChatUserModel.fromJson(json['client']);
    }
    if (p2 == null && json['astrologer'] != null) {
      p2 = ChatUserModel.fromJson(json['astrologer']);
    }

    // Format 4: user / otherUser structure
    if (p1 == null && json['user'] != null) {
      p1 = ChatUserModel.fromJson(json['user']);
    }
    if (p2 == null && json['otherUser'] != null) {
      p2 = ChatUserModel.fromJson(json['otherUser']);
    }

    // Handle lastMessage in different formats
    MessagePreviewModel? lastMsg;
    if (json['lastMessage'] != null) {
      if (json['lastMessage'] is Map) {
        lastMsg = MessagePreviewModel.fromJson(json['lastMessage']);
      } else if (json['lastMessage'] is String) {
        // lastMessage is just the text
        lastMsg = MessagePreviewModel(
          id: '',
          content: json['lastMessage'],
          type: 'TEXT',
          senderId: '',
          isRead: false,
          createdAt: DateTime.now(),
        );
      }
    } else if (json['lastMessageText'] != null) {
      // Alternative format: lastMessageText
      lastMsg = MessagePreviewModel(
        id: '',
        content: json['lastMessageText'],
        type: 'TEXT',
        senderId: '',
        isRead: false,
        createdAt: DateTime.now(),
      );
    }

    return ConversationModel(
      id: json['id'] ?? json['_id'] ?? json['chatId'] ?? '',
      participant1Id: json['participant1Id'] ?? json['clientId'] ?? p1?.id ?? '',
      participant2Id: json['participant2Id'] ?? json['astrologerId'] ?? p2?.id ?? '',
      participant1: p1,
      participant2: p2,
      lastMessage: lastMsg,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'])
          : (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null),
      participant1HasUnread: json['participant1HasUnread'] ?? json['hasUnread'] ?? false,
      participant2HasUnread: json['participant2HasUnread'] ?? false,
      unreadCount: json['unreadCount'] ?? json['unread'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Get the other participant (client) for the astrologer
  ChatUserModel? getOtherParticipant(String currentUserId) {
    // If current user is participant1, return participant2
    if (participant1?.id == currentUserId) {
      return participant2;
    }
    // If current user is participant2, return participant1
    if (participant2?.id == currentUserId) {
      return participant1;
    }
    // If we can't match by ID, check roles
    if (participant1?.role == 'ASTROLOGER' || participant1?.role == 'astrologer') {
      return participant2; // Return the client
    }
    if (participant2?.role == 'ASTROLOGER' || participant2?.role == 'astrologer') {
      return participant1; // Return the client
    }
    // Default: return participant1 (usually the client)
    return participant1 ?? participant2;
  }

  /// Check if the current user has unread messages
  bool hasUnread(String currentUserId) {
    if (participant1Id == currentUserId) {
      return participant1HasUnread;
    }
    return participant2HasUnread;
  }
}

/// Message preview for conversation list
class MessagePreviewModel {
  final String id;
  final String content;
  final String type;
  final String senderId;
  final bool isRead;
  final DateTime createdAt;

  MessagePreviewModel({
    required this.id,
    required this.content,
    required this.type,
    required this.senderId,
    required this.isRead,
    required this.createdAt,
  });

  factory MessagePreviewModel.fromJson(Map<String, dynamic> json) {
    return MessagePreviewModel(
      id: json['id'] ?? json['_id'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      senderId: json['senderId'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

// ============================================================
// CHAT HISTORY
// ============================================================

class ChatHistoryResponse {
  final List<ChatMessageModel> messages;
  final ChatUserModel? otherUser;
  final String? chatId;
  final int? totalCount;
  final bool? hasMore;

  ChatHistoryResponse({
    required this.messages,
    this.otherUser,
    this.chatId,
    this.totalCount,
    this.hasMore,
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] ?? json['data'] ?? [];
    return ChatHistoryResponse(
      messages: (messagesList as List)
          .map((m) => ChatMessageModel.fromJson(m))
          .toList(),
      otherUser: json['otherUser'] != null
          ? ChatUserModel.fromJson(json['otherUser'])
          : null,
      chatId: json['chatId'],
      totalCount: json['totalCount'],
      hasMore: json['hasMore'],
    );
  }
}

/// Full message model
class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final String type;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;
  final ChatUserModel? sender;

  ChatMessageModel({
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

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? json['_id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      metadata: json['metadata'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      sender: json['sender'] != null
          ? ChatUserModel.fromJson(json['sender'])
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
      'type': type,
      'metadata': metadata,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'sender': sender?.toJson(),
    };
  }
}

// ============================================================
// BROADCAST MESSAGE MODEL
// ============================================================

class BroadcastMessageModel {
  final String id;
  final String clientId;
  final String content;
  final String? type;
  final BroadcastStatus status;
  final String? acceptedBy;
  final DateTime? acceptedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final ChatUserModel? client;
  final ChatUserModel? acceptedAstrologer;

  BroadcastMessageModel({
    required this.id,
    required this.clientId,
    required this.content,
    this.type,
    required this.status,
    this.acceptedBy,
    this.acceptedAt,
    this.expiresAt,
    required this.createdAt,
    this.client,
    this.acceptedAstrologer,
  });

  factory BroadcastMessageModel.fromJson(Map<String, dynamic> json) {
    return BroadcastMessageModel(
      id: json['id'] ?? json['_id'] ?? '',
      clientId: json['clientId'] ?? '',
      content: json['content'] ?? '',
      type: json['type'],
      status: BroadcastStatus.fromString(json['status'] ?? 'PENDING'),
      acceptedBy: json['acceptedBy'],
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      client: json['client'] != null
          ? ChatUserModel.fromJson(json['client'])
          : null,
      acceptedAstrologer: json['acceptedAstrologer'] != null
          ? ChatUserModel.fromJson(json['acceptedAstrologer'])
          : null,
    );
  }

  /// Check if the broadcast is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get remaining time until expiry
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Response when accepting a broadcast
class AcceptBroadcastResponse {
  final bool success;
  final String? message;
  final String? chatId;
  final ChatUserModel? client;
  final Map<String, dynamic>? chat;

  AcceptBroadcastResponse({
    required this.success,
    this.message,
    this.chatId,
    this.client,
    this.chat,
  });

  factory AcceptBroadcastResponse.fromJson(Map<String, dynamic> json) {
    return AcceptBroadcastResponse(
      success: json['success'] ?? true,
      message: json['message'],
      chatId: json['chatId'] ?? json['chat']?['id'],
      client: json['client'] != null
          ? ChatUserModel.fromJson(json['client'])
          : null,
      chat: json['chat'],
    );
  }
}

// ============================================================
// INSTANT CHAT REQUEST MODEL
// ============================================================

class InstantChatRequestModel {
  final String id;
  final String clientId;
  final String? astrologerId;
  final String? message;
  final InstantChatStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final ChatUserModel? client;

  InstantChatRequestModel({
    required this.id,
    required this.clientId,
    this.astrologerId,
    this.message,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.client,
  });

  factory InstantChatRequestModel.fromJson(Map<String, dynamic> json) {
    return InstantChatRequestModel(
      id: json['id'] ?? json['_id'] ?? '',
      clientId: json['clientId'] ?? '',
      astrologerId: json['astrologerId'],
      message: json['message'],
      status: InstantChatStatus.fromString(json['status'] ?? 'PENDING'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      client: json['client'] != null
          ? ChatUserModel.fromJson(json['client'])
          : null,
    );
  }

  /// Check if the request is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Response when accepting an instant chat
class AcceptInstantChatResponse {
  final bool success;
  final String? message;
  final String? chatId;
  final ChatUserModel? client;
  final Map<String, dynamic>? chat;

  AcceptInstantChatResponse({
    required this.success,
    this.message,
    this.chatId,
    this.client,
    this.chat,
  });

  factory AcceptInstantChatResponse.fromJson(Map<String, dynamic> json) {
    return AcceptInstantChatResponse(
      success: json['success'] ?? true,
      message: json['message'],
      chatId: json['chatId'] ?? json['chat']?['id'],
      client: json['client'] != null
          ? ChatUserModel.fromJson(json['client'])
          : null,
      chat: json['chat'],
    );
  }
}

// ============================================================
// ONLINE STATUS
// ============================================================

class OnlineStatusResponse {
  final bool isOnline;
  final String? message;
  final DateTime? lastToggled;

  OnlineStatusResponse({
    required this.isOnline,
    this.message,
    this.lastToggled,
  });

  factory OnlineStatusResponse.fromJson(Map<String, dynamic> json) {
    return OnlineStatusResponse(
      isOnline: json['isOnline'] ?? json['online'] ?? false,
      message: json['message'],
      lastToggled: json['lastToggled'] != null
          ? DateTime.tryParse(json['lastToggled'])
          : null,
    );
  }
}

// ============================================================
// FILE UPLOAD
// ============================================================

class FileUploadResponse {
  final bool success;
  final String? fileUrl;
  final String? url;
  final String? fileName;
  final String? fileType;
  final int? fileSize;

  FileUploadResponse({
    required this.success,
    this.fileUrl,
    this.url,
    this.fileName,
    this.fileType,
    this.fileSize,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      success: json['success'] ?? true,
      fileUrl: json['fileUrl'],
      url: json['url'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
    );
  }

  /// Get the actual file URL
  String? get actualUrl => fileUrl ?? url;
}
