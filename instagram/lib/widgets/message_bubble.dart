import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback onExpire;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onExpire,
  });

  @override
  Widget build(BuildContext context) {
    // Optional: Hide if manually set to invisible elsewhere
    if (!message.isVisible) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? const Color(0xFF8B5CF6) : const Color(0xFF1E004B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}