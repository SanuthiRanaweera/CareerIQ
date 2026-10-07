import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/app_notification.dart';

void main() {
  test('decodes notification content and read state', () {
    final notification = AppNotification.fromJson({
      '_id': 'notice-1',
      'title': 'Application reminder',
      'message': 'Submit your application by Friday.',
      'createdAt': '2026-10-05T08:00:00.000Z',
      'readAt': null,
    });

    expect(notification.id, 'notice-1');
    expect(notification.title, 'Application reminder');
    expect(notification.message, 'Submit your application by Friday.');
    expect(notification.isRead, isFalse);
  });

  test('decodes student recipient details', () {
    final recipient = NotificationRecipient.fromJson({
      '_id': 'student-1',
      'fullName': 'A Student',
      'email': 'student@example.com',
      'school': 'Central College',
    });

    expect(recipient.id, 'student-1');
    expect(recipient.fullName, 'A Student');
    expect(recipient.email, 'student@example.com');
    expect(recipient.school, 'Central College');
  });
}
