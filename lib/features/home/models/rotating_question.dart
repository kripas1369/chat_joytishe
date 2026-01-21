class RotatingQuestion {
  final String id;
  final String title;
  final String subtitle;
  final bool isActive;
  final int sortOrder;

  RotatingQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.sortOrder,
  });

  factory RotatingQuestion.fromJson(Map<String, dynamic> json) {
    return RotatingQuestion(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class RotatingQuestionsResponse {
  final bool success;
  final List<RotatingQuestion> items;

  RotatingQuestionsResponse({required this.success, required this.items});

  factory RotatingQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final items = <RotatingQuestion>[];
    if (json['data'] != null && json['data']['items'] != null) {
      for (var item in json['data']['items']) {
        items.add(RotatingQuestion.fromJson(item));
      }
    }
    return RotatingQuestionsResponse(
      success: json['success'] ?? false,
      items: items,
    );
  }
}
