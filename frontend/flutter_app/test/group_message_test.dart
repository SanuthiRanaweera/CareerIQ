import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/group_message.dart';

void main() {
  test('decodes shared message and sender identity', () {
    final message = GroupMessage.fromJson({
      '_id': 'message-1',
      'senderId': 'user-1',
      'senderStudentId': 'student-1',
      'senderName': 'A Student',
      'senderProfileImage': 'https://example.com/student.png',
      'message': 'Hello everyone',
      'createdAt': '2026-10-08T09:30:00.000Z',
    });

    expect(message.id, 'message-1');
    expect(message.senderStudentId, 'student-1');
    expect(message.senderName, 'A Student');
    expect(message.senderProfileImage, 'https://example.com/student.png');
    expect(message.message, 'Hello everyone');
  });
}
