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
