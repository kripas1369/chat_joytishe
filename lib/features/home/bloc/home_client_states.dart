import 'package:chat_jyotishi/features/home/models/rotating_question.dart';
import 'package:equatable/equatable.dart';

abstract class HomeClientState extends Equatable {
  const HomeClientState();

  @override
  List<Object?> get props => [];
}

class RotatingQuestionsInitialState extends HomeClientState {}

class RotatingQuestionsLoadingState extends HomeClientState {}

class RotatingQuestionsLoadedState extends HomeClientState {
  final List<RotatingQuestion> questions;
  final int currentIndex;

  const RotatingQuestionsLoadedState({
    required this.questions,
    this.currentIndex = 0,
  });

  RotatingQuestion get currentQuestion => questions[currentIndex];

  RotatingQuestionsLoadedState copyWith({
    List<RotatingQuestion>? questions,
    int? currentIndex,
  }) {
    return RotatingQuestionsLoadedState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [questions, currentIndex];
}

class RotatingQuestionsErrorState extends HomeClientState {
  final String message;

  const RotatingQuestionsErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

class RotatingQuestionsEmptyState extends HomeClientState {}
