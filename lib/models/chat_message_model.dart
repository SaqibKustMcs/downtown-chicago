class ChatMessage {
  final String text;
  final DateTime timestamp;
  final bool isSent; // true if sent by current user, false if received
  final String? avatarUrl;

  const ChatMessage({
    required this.text,
    required this.timestamp,
    required this.isSent,
    this.avatarUrl,
  });
}
