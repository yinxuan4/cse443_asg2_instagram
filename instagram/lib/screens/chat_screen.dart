// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:instagram/models/moderation_rule.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mock initial data
  List<ChatMessage> messages = [
    ChatMessage(
      id: '1',
      text: 'Wei, you done with the software assignment?',
      isMe: false,
    ),
    ChatMessage(
      id: '2',
      text: 'Not yet la, still debugging the flutter UI 😭',
      isMe: true,
    ),
    ChatMessage(id: '3', text: 'Gila, due is this Sunday right?', isMe: false),
    ChatMessage(id: '4', text: 'Ya man, stressing out rn.', isMe: true),
    ChatMessage(
      id: '5',
      text: 'Wanna go mamak later? Get some teh o ais to chill',
      isMe: false,
    ),
    ChatMessage(
      id: '6',
      text: 'Onzzzz. Need a screen break anyway.',
      isMe: true,
    ),
    ChatMessage(id: '7', text: '10pm at the usual place?', isMe: false),
    ChatMessage(id: '8', text: 'Cun. See ya later', isMe: true),
  ];

  // ==========================================
  // REQUIREMENT 1: Real-Time Moderation Filter
  // ==========================================
  final List<ModerationRule> _rules = [
    // 1. Scam & Security Rule
    ModerationRule(
      ViolationType.scam,
      RegExp(r'\b(scam|phishing|hack(er|ing)?)\b', caseSensitive: false),
      'Message blocked: Potential security threat detected.',
    ),

    // 2. Profanity Rule
    ModerationRule(
      ViolationType.profanity,
      RegExp(r'\b(damn+|hell+|crap+?)\b', caseSensitive: false),
      'Message blocked: Please keep the conversation clean.',
    ),

    // 3. Link Spam Rule
    ModerationRule(
      ViolationType.linkSpam,
      RegExp(r'(https?:\/\/|www\.)[^\s]+', caseSensitive: false),
      'Message blocked: External links are currently disabled.',
    ),
  ];

  void _sendMessage() {
    String text = _textController.text.trim();
    if (text.isEmpty) return;

    String? triggerWarning;

    // The Regex Engine Loop
    for (var rule in _rules) {
      if (rule.pattern.hasMatch(text)) {
        triggerWarning = rule.warningMessage;
        break;
      }
    }

    if (triggerWarning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(triggerWarning),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // If safe, create message
    setState(() {
      messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          text: text,
          isMe: true,
          isEphemeral: true,
        ),
      );
    });

    _textController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Callback to handle when a message self-destructs
  void _onMessageExpired(String id) {
    setState(() {
      final msg = messages.firstWhere((m) => m.id == id);
      msg.isVisible = false;
      msg.text = "[Message Expired]";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C0069), Color(0xFF4A00B4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(
                      message: messages[index],
                      onExpire: () => _onMessageExpired(messages[index].id),
                    );
                  },
                ),
              ),
              _buildBottomInput(),
            ],
          ),
        ],
      ),
    );
  }

  // --- APP BAR UI ---
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
      title: Row(
        children: [
          // ERROR FIXED HERE: Replaced NetworkImage with an Icon
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'shuyi >',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'shuyi.123',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.phone_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
      ],
    );
  }

  // --- BOTTOM INPUT UI ---
  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C0069),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
