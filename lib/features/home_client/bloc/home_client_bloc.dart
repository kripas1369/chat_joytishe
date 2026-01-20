import 'package:chat_jyotishi/features/home_client/bloc/home_client_events.dart';
import 'package:chat_jyotishi/features/home_client/bloc/home_client_states.dart';
import 'package:chat_jyotishi/features/home_client/repository/home_client_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class HomeClientBloc
    extends Bloc<HomeClientEvent, HomeClientState> {
  final HomeClientRepository repository;

  HomeClientBloc({required this.repository})
    : super(RotatingQuestionsInitialState()) {
    on<LoadRotatingQuestionsEvent>(_onLoadQuestions);
    on<NextQuestionEvent>(_onNextQuestion);
    on<PreviousQuestionEvent>(_onPreviousQuestion);
  }

  Future<void> _onLoadQuestions(
    LoadRotatingQuestionsEvent event,
    Emitter<HomeClientState> emit,
  ) async {
    try {
      debugPrint('🔄 BLoC: Loading questions...');
      emit(RotatingQuestionsLoadingState());

      final questions = await repository.fetchQuestions();

      if (questions.isEmpty) {
        debugPrint('⚠️ BLoC: No questions available');
        emit(RotatingQuestionsEmptyState());
      } else {
        debugPrint('✅ BLoC: ${questions.length} questions loaded');
        emit(RotatingQuestionsLoadedState(questions: questions));
      }
    } catch (e) {
      debugPrint('❌ BLoC Error: $e');
      emit(
        RotatingQuestionsErrorState(
          message: 'Failed to load questions: ${e.toString()}',
        ),
      );
    }
  }

  void _onNextQuestion(
    NextQuestionEvent event,
    Emitter<HomeClientState> emit,
  ) {
    if (state is RotatingQuestionsLoadedState) {
      final currentState = state as RotatingQuestionsLoadedState;
      final nextIndex =
          (currentState.currentIndex + 1) % currentState.questions.length;

      debugPrint('➡️ BLoC: Moving to question $nextIndex');
      emit(currentState.copyWith(currentIndex: nextIndex));
    }
  }

  void _onPreviousQuestion(
    PreviousQuestionEvent event,
    Emitter<HomeClientState> emit,
  ) {
    if (state is RotatingQuestionsLoadedState) {
      final currentState = state as RotatingQuestionsLoadedState;
      final previousIndex = currentState.currentIndex == 0
          ? currentState.questions.length - 1
          : currentState.currentIndex - 1;

      debugPrint('⬅️ BLoC: Moving to question $previousIndex');
      emit(currentState.copyWith(currentIndex: previousIndex));
    }
  }
}
