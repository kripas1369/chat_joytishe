import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';

abstract class ChatState {
  const ChatState();
}

class ChatInitialState extends ChatState {
  const ChatInitialState();
}

class ChatLoadingState extends ChatState {
  const ChatLoadingState();
}

class ChatErrorState extends ChatState {
  final String message;

  const ChatErrorState(this.message);
}

/// Success state when online jyotish list fetched successfully
class ActiveUsersLoadedState extends ChatState {
  final List<ActiveAstrologerModel> astrologers;

  const ActiveUsersLoadedState(this.astrologers);
}

/// Success state when chat ended successfully
class ChatEndSuccessState extends ChatState {
  final String chatId;
  final String endedBy;
  final DateTime endedAt;

  const ChatEndSuccessState({
    required this.chatId,
    required this.endedBy,
    required this.endedAt,
  });

  List<Object?> get props => [chatId, endedBy, endedAt];
}
