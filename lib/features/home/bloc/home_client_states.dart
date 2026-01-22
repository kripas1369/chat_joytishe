import 'package:chat_jyotishi/features/home/models/book_pandit_model.dart';
import 'package:chat_jyotishi/features/home/models/rotating_question.dart';
import 'package:equatable/equatable.dart';

abstract class HomeClientState extends Equatable {
  const HomeClientState();

  @override
  List<Object?> get props => [];
}

class HomeClientInitialState extends HomeClientState {}

class HomeClientLoadingState extends HomeClientState {}

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

class HomeClientBookingSuccess extends HomeClientState {
  final BookingModel booking;

  const HomeClientBookingSuccess(this.booking);
}

class HomeClientErrorState extends HomeClientState {
  final String message;

  const HomeClientErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

class RotatingQuestionsEmptyState extends HomeClientState {}
