class ChatMessage {
  final String id;
  final String userId;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  // Convertir desde la base de datos local
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'].toString(),
      userId: map['user_id'] as String,
      text: map['text'] as String,
      isUser: (map['is_user'] as int? ?? 0) == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  // Convertir para guardar en la base de datos local
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
