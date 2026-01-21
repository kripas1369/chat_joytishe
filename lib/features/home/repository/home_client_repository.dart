import 'package:chat_jyotishi/features/home/models/rotating_question.dart';
import 'package:chat_jyotishi/features/home/service/home_client_service.dart';
import 'package:flutter/material.dart';

class HomeClientRepository {
  final HomeClientService _service;

  HomeClientRepository(this._service);

  Future<List<RotatingQuestion>> fetchQuestions() async {
    try {
      debugPrint('📦 Repository: Fetching questions...');

      final response = await _service.fetchRotatingQuestions();

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
}
