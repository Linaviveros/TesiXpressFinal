import 'message_role.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'role': role.name,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}
