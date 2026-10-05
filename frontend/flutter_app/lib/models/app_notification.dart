class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
      );

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}

class NotificationRecipient {
  const NotificationRecipient({
    required this.id,
    required this.fullName,
    required this.email,
    this.school = '',
  });

  factory NotificationRecipient.fromJson(Map<String, dynamic> json) =>
      NotificationRecipient(
        id: json['_id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        school: json['school'] as String? ?? '',
      );

  final String id;
  final String fullName;
  final String email;
  final String school;
}
