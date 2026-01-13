import 'package:chat_jyotishi/features/chat/bloc/chat_events.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_states.dart';
import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  List<ActiveAstrologerModel> _cachedActiveAstrologers = [];

  ChatBloc({required this.chatRepository}) : super(const ChatInitialState()) {
    on<FetchActiveUsersEvent>(_onFetchActiveAstrologers);
    on<RefreshActiveUsersEvent>(_onRefreshActiveAstrologers);
    on<EndChatRequestedEvent>(_onEndChatRequested);
    on<ChatEndResetEvent>(_onChatEndReset);
  }

  // Fetch active astrologers initially
  Future<void> _onFetchActiveAstrologers(
    FetchActiveUsersEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoadingState());
    try {
      final activeAstrologers = await chatRepository.getActiveAstrologers();
      _cachedActiveAstrologers = activeAstrologers;
      emit(ActiveUsersLoadedState(activeAstrologers));
    } catch (e) {
      emit(ChatErrorState(e.toString()));
    }
  }

  // Refresh the active astrologers list
  Future<void> _onRefreshActiveAstrologers(
    RefreshActiveUsersEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (_cachedActiveAstrologers.isNotEmpty) {
      emit(ActiveUsersLoadedState(_cachedActiveAstrologers));
    } else {
      emit(const ChatLoadingState());
    }

    try {
      final activeAstrologers = await chatRepository.getActiveAstrologers();
      _cachedActiveAstrologers = activeAstrologers;
      emit(ActiveUsersLoadedState(activeAstrologers));
    } catch (e) {
      if (_cachedActiveAstrologers.isNotEmpty) {
        emit(ChatErrorState(e.toString()));
        emit(ActiveUsersLoadedState(_cachedActiveAstrologers));
      } else {
        emit(ChatErrorState(e.toString()));
      }
    }
  }

  Future<void> _onEndChatRequested(
    EndChatRequestedEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoadingState());

    try {
      final result = await chatRepository.endChat(chatId: event.chatId);

      emit(
        ChatEndSuccessState(
          chatId: result['chatId'] as String,
          endedBy: result['endedBy'] as String,
          endedAt: result['endedAt'] as DateTime,
        ),
      );
    } catch (e) {
      emit(ChatErrorState(e.toString()));
    }
  }

  /// Reset the state
  void _onChatEndReset(ChatEndResetEvent event, Emitter<ChatState> emit) {
    emit(const ChatInitialState());
  }
}
