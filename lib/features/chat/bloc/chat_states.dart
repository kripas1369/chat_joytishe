import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';

abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ActiveUsersLoading extends ChatState {
  const ActiveUsersLoading();
}

class ActiveUsersLoaded extends ChatState {
  final List<ActiveAstrologerModel> astrologers;

  const ActiveUsersLoaded(this.astrologers);
}

class ActiveUsersError extends ChatState {
  final String message;

  const ActiveUsersError(this.message);
}
