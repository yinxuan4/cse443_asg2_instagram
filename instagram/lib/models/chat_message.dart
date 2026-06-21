class ChatMessage {
  final String id;
  String text;
  final String senderId;
  final bool isEphemeral;
  bool isVisible;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    this.isEphemeral = false,
    this.isVisible = true,
  });
}
