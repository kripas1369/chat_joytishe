class ApiEndpoints {
  static const String serverUrl = 'http://192.168.0.206:4000';

  ///production api
  static const String baseUrl =
      'https://jotishapi.autonomoustechnology.net/api/v1';

  // static const String baseUrl = 'http://192.168.0.206:4000/api/v1';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String setPassword = '$baseUrl/auth/set-password';
  static const String clientLoginWithPassword = '$baseUrl/auth/login';
  static const String astrologerLoginWithPassword =
      '$baseUrl/astrologer/auth/login';
  static const String loginWithOtp = '$baseUrl/auth/login-with-otp';
  static const String verifyLoginOtp = '$baseUrl/auth/verify-login-otp';
  static const String changePassword = '$baseUrl/auth/change-password';
  static const String getActiveAstrologers = '$baseUrl/users/chatable';
  static const String getAstrologerProfile = '$baseUrl/astrologers/:id';
  static const String getCurrentUserProfile = '$baseUrl/users/me';
  static const String completeUserProfileSetup = '$baseUrl/users/profile-setup';
  static const String updateUserProfile = '$baseUrl/users/me';
  static const String updateUserBirthDetails =
      '$baseUrl/users/me/birth-details';
  static const String uploadProfilePhoto = '$baseUrl/users/upload-photo';
  static const String removeProfilePhoto = '$baseUrl/users/remove-photo';

  static const String socketUrl = 'http://192.168.0.206:4000';

  // API Endpoints (relative to baseUrl)
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshEndpoint = '/auth/refresh';
  static const String currentUser = '/users/me';

  // Chat Endpoints
  static const String chatConversations = '/chat/conversations';
  static const String chatChats = '/chat/chats';
  static const String chatHistory = '/chat/history';
  static const String chatMessages = '/chat/messages';
  static const String chatUploadFile = '/chat/upload-file';
  static const String chatUnreadCount = '/chat/unread-count';
  static const String chatSearch = '/chat/search';
  static const String chatActiveChat = '/chat/active-chat';
  static const String chatEnd = '/chats';
  static const String chatMarkRead =
      '/chat/chats'; // PUT /chat/chats/:chatId/read

  // Appointment Endpoints
  static const String appointments = '$baseUrl/appointments';
  static const String appointmentById = '$baseUrl/appointments'; // + /:id

  //Book Pandit EndPoints
  static const String bookPandit = '$baseUrl/jyotish-bookings';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static const String notificationMarkAllRead = '/notifications/mark-all-read';

  // FCM Token Registration
  static const String registerFcmToken = '/users/fcm-token';
  static const String removeFcmToken = '/users/fcm-token';

  // Astrologer Chat Endpoints
  static const String broadcastMessagesPending = '/broadcast-messages/pending';
  static const String broadcastMessagesAll = '/broadcast-messages/all';
  static const String broadcastMessagesAccept =
      '/broadcast-messages'; // + /:messageId/accept
  static const String broadcastMessagesDismiss =
      '/broadcast-messages'; // + /:messageId/dismiss
  static const String instantChatPending = '/instant-chat/pending';
  static const String instantChatAccept =
      '/instant-chat/accept'; // + /:requestId
  static const String instantChatStatus = '/instant-chat/status';
  static const String astrologerToggleOnline = '/astrologer/toggle-online';
  static const String userDetails = '/users'; // + /:id/details
  static const String chatableUsers = '/users/chatable';
}
