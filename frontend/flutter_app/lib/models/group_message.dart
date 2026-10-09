class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderStudentId,
    required this.senderName,
    required this.senderProfileImage,
    required this.message,
    required this.createdAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) => GroupMessage(
    id: json['_id'] as String? ?? json['id'] as String? ?? '',
    senderId: json['senderId'] as String? ?? '',
    senderStudentId: json['senderStudentId'] as String? ?? '',
    senderName: json['senderName'] as String? ?? 'CareerIQ user',
    senderProfileImage: json['senderProfileImage'] as String? ?? '',
    message: json['message'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  final String id;
  final String senderId;
  final String senderStudentId;
  final String senderName;
  final String senderProfileImage;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'senderId': senderId,
    'senderStudentId': senderStudentId,
    'senderName': senderName,
    'senderProfileImage': senderProfileImage,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };

  GroupMessage copyWith({
    String? message,
    String? senderName,
    String? senderProfileImage,
  }) => GroupMessage(
    id: id,
    senderId: senderId,
    senderStudentId: senderStudentId,
    senderName: senderName ?? this.senderName,
    senderProfileImage: senderProfileImage ?? this.senderProfileImage,
    message: message ?? this.message,
    createdAt: createdAt,
  );
}
