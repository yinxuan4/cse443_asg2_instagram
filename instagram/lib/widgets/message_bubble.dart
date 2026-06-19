// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_message.dart';

class MessageBubble extends StatefulWidget {
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
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  Timer? _timer;
  int _timeLeft = 5; // 5-second self-destruct timer
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    // ===============================================
    // REQUIREMENT 2: Ephemeral Self-Destruct Sequence
    // ===============================================
    if (widget.message.isEphemeral && widget.message.isVisible) {
      _startSelfDestructTimer();
    }
  }

  void _startSelfDestructTimer() {
    setState(() => _timerStarted = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        widget.onExpire(); // Trigger UI update in parent
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.message.isVisible) {
      return const SizedBox.shrink(); // Hide message completely when expired
    }

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isMe ? const Color(0xFF8B5CF6) : const Color(0xFF1E004B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message.text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            // Show the countdown timer if it's an ephemeral message
            if (widget.message.isEphemeral && _timerStarted)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Destructing in ${_timeLeft}s',
                  style: const TextStyle(
                    color: Colors.redAccent, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}