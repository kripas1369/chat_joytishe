import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class FetchActiveUsersEvent extends ChatEvent {
  const FetchActiveUsersEvent();
}

class RefreshActiveUsersEvent extends ChatEvent {
  const RefreshActiveUsersEvent();
}

class ClearSelectedUserEvent extends ChatEvent {
  const ClearSelectedUserEvent();
}

/// Event to end chat
class EndChatRequestedEvent extends ChatEvent {
  final String chatId;

  const EndChatRequestedEvent({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

/// Event to reset the state
class ChatEndResetEvent extends ChatEvent {
  const ChatEndResetEvent();
}
