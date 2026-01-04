import 'package:chat_jyotishi/features/chat/bloc/chat_events.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_states.dart';
import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  List<ActiveAstrologerModel> _cachedActiveAstrologers = [];

  ChatBloc({required this.chatRepository}) : super(const ChatInitial()) {
    on<FetchActiveUsersEvent>(_onFetchActiveAstrologers);
    on<RefreshActiveUsersEvent>(_onRefreshActiveAstrologers);
  }

  // Fetch active astrologers initially
  Future<void> _onFetchActiveAstrologers(
      FetchActiveUsersEvent event,
      Emitter<ChatState> emit,
      ) async {
    emit(const ActiveUsersLoading());
    try {
      final activeAstrologers = await chatRepository.getActiveAstrologers();
      _cachedActiveAstrologers = activeAstrologers;
      emit(ActiveUsersLoaded(activeAstrologers));
    } catch (e) {
      emit(ActiveUsersError(e.toString()));
    }
  }

  // Refresh the active astrologers list
  Future<void> _onRefreshActiveAstrologers(
      RefreshActiveUsersEvent event,
      Emitter<ChatState> emit,
      ) async {
    if (_cachedActiveAstrologers.isNotEmpty) {
      emit(ActiveUsersLoaded(_cachedActiveAstrologers));
    } else {
      emit(const ActiveUsersLoading());
    }

    try {
      final activeAstrologers = await chatRepository.getActiveAstrologers();
      _cachedActiveAstrologers = activeAstrologers;
      emit(ActiveUsersLoaded(activeAstrologers));
    } catch (e) {
      if (_cachedActiveAstrologers.isNotEmpty) {
        emit(ActiveUsersError(e.toString()));
        emit(ActiveUsersLoaded(_cachedActiveAstrologers));
      } else {
        emit(ActiveUsersError(e.toString()));
      }
    }
  }
}
