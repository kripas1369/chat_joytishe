import 'package:chat_jyotishi/features/home/models/book_pandit_model.dart';
import 'package:chat_jyotishi/features/home/models/rotating_question.dart';
import 'package:chat_jyotishi/features/home/service/home_client_service.dart';
import 'package:flutter/material.dart';

class HomeClientRepository {
  final HomeClientService homeClientService;

  HomeClientRepository(this.homeClientService);

  Future<List<RotatingQuestion>> fetchQuestions() async {
    try {
      debugPrint('📦 Repository: Fetching questions...');

      final response = await homeClientService.fetchRotatingQuestions();

      if (response.success && response.items.isNotEmpty) {
        // Sort by sortOrder
        final sortedItems = List<RotatingQuestion>.from(response.items)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        debugPrint('✅ Repository: ${sortedItems.length} questions fetched');
        return sortedItems;
      } else {
        debugPrint('⚠️ Repository: No questions available');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Repository Error: $e');
      rethrow;
    }
  }

  Future<BookingModel> bookPandit({
    required String bookingDate,
    required String category,
    required String type,
    required String location,
  }) async {
    final response = await homeClientService.bookPandit(
      bookingDate: bookingDate,
      category: category,
      type: type,
      location:location,
    );

    return BookingModel.fromJson(response['data']['booking']);
  }
}
