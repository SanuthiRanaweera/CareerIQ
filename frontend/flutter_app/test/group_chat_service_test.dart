import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/group_message.dart';

void main() {
  test('GroupMessage toJson and fromJson roundtrip', () {
    final now = DateTime.now();
    final message = GroupMessage(
      id: 'msg-1',
      senderId: 'user-1',
      senderStudentId: 'student-1',
      senderName: 'John Doe',
      senderProfileImage: 'https://example.com/photo.jpg',
      message: 'Hello world',
      createdAt: now,
    );

    final json = message.toJson();
    final decoded = GroupMessage.fromJson(json);

    expect(decoded.id, 'msg-1');
    expect(decoded.senderId, 'user-1');
    expect(decoded.senderStudentId, 'student-1');
    expect(decoded.senderName, 'John Doe');
    expect(decoded.senderProfileImage, 'https://example.com/photo.jpg');
    expect(decoded.message, 'Hello world');
  });

  test('GroupMessage copyWith updates fields correctly', () {
    final message = GroupMessage(
      id: 'msg-1',
      senderId: 'user-1',
      senderStudentId: 'student-1',
      senderName: 'John Doe',
      senderProfileImage: 'https://example.com/photo.jpg',
      message: 'Hello world',
      createdAt: DateTime.now(),
    );

    final updated = message.copyWith(
      message: 'Updated message',
      senderName: 'Jane Doe',
    );
    expect(updated.message, 'Updated message');
    expect(updated.senderName, 'Jane Doe');
    expect(updated.id, 'msg-1');
  });
}
