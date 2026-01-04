import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatRepository {
  final ChatService chatService;

  ChatRepository(this.chatService);

  Future<List<ActiveAstrologerModel>> getActiveAstrologers() async {
    final response = await chatService.fetchActiveAstrologers();

    if (response['success'] == true && response['data'] is List) {
      return (response['data'] as List)
          .map((e) => ActiveAstrologerModel.fromJson(e))
          .toList();
    }

    return [];
  }

  // Future<Map<String, dynamic>> getAstrologerProfile(String astrologerId) async {
  //   final data = await chatService.fetchAstrologerProfile(astrologerId);
  //   await _storeSelectedAstrologerId(astrologerId);
  //   return data;
  // }
  //
  // Future<void> _storeSelectedAstrologerId(String astrologerId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('selected_astrologer_id', astrologerId);
  // }
  //
  // Future<String?> getStoredAstrologerId() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('selected_astrologer_id');
  // }
  //
  // Future<void> clearStoredAstrologerId() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('selected_astrologer_id');
  // }
}
