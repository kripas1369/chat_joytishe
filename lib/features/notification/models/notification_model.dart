class NotificationModel {
  final String id;
  final String userId;
  final String? astrologerId;
  final String recipientType;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final String groupKey;
  final int count;
  final DateTime lastUpdated;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.astrologerId,
    required this.recipientType,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.metadata,
    required this.groupKey,
    required this.count,
    required this.lastUpdated,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      astrologerId: json['astrologerId'],
      recipientType: json['recipientType'] ?? 'CLIENT',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      groupKey: json['groupKey'] ?? '',
      count: json['count'] ?? 1,
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'astrologerId': astrologerId,
      'recipientType': recipientType,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'metadata': metadata,
      'groupKey': groupKey,
      'count': count,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? astrologerId,
    String? recipientType,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    Map<String, dynamic>? metadata,
    String? groupKey,
    int? count,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      astrologerId: astrologerId ?? this.astrologerId,
      recipientType: recipientType ?? this.recipientType,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      groupKey: groupKey ?? this.groupKey,
      count: count ?? this.count,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationResponse {
  final bool success;
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;
  final int limit;
  final int offset;
  final String message;

  NotificationResponse({
    required this.success,
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.limit,
    required this.offset,
    required this.message,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final notificationsList = data['notifications'] as List<dynamic>? ?? [];

    return NotificationResponse(
      success: json['success'] ?? false,
      notifications: notificationsList
          .map(
            (notification) => NotificationModel.fromJson(
              notification as Map<String, dynamic>,
            ),
          )
          .toList(),
      total: data['total'] ?? 0,
      unreadCount: data['unreadCount'] ?? 0,
      limit: data['limit'] ?? 5,
      offset: data['offset'] ?? 0,
      message: data['message'] ?? '',
    );
  }
}
