abstract class HomeClientEvent {}

class LoadRotatingQuestionsEvent extends HomeClientEvent {}

class NextQuestionEvent extends HomeClientEvent {}

class PreviousQuestionEvent extends HomeClientEvent {}

class BookPanditEvent extends HomeClientEvent {
  final String bookingDate;
  final String category;
  final String type;
  final String location;

  BookPanditEvent({
    required this.type,
    required this.bookingDate,
    required this.category,
    required this.location,
  });
}
