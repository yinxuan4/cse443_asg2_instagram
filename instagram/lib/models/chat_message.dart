class ChatMessage {
  final String id;
  String text;
  final bool isMe;
  final bool isEphemeral; // Flag for Requirement 2
  bool isVisible;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    this.isEphemeral = false,
    this.isVisible = true,
  });
}