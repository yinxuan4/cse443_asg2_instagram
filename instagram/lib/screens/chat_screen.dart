import 'package:flutter/material.dart';
import 'package:instagram/models/moderation_rule.dart';
import '../config/user_config.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/scribble_canvas.dart';
import 'login_screen.dart';
import 'scribble_demo_screen.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String displayName;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

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
    if (text.isEmpty) {
      return;
    }

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
          isEphemeral: false, // <-- CHANGED THIS TO FALSE TO DISABLE DESTRUCTION
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

  void _openScribbleDemo() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ScribbleDemoScreen()),
    );
  }

  void _openScribble() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: AppTheme.scribbleSheetDecoration(),
        clipBehavior: Clip.antiAlias,
        child: ScribbleCanvas(userId: widget.userId),
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            decoration: AppTheme.gradientBackground(),
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
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == widget.userId,
                      onExpire: () => _onMessageExpired(message.id),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _logout,
      ),
      title: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  partnerDisplayName(widget.userId),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'You: ${displayNameFor(widget.userId)}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'split_demo') {
              _openScribbleDemo();
            } else if (value == 'logout') {
              _logout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'split_demo',
              child: Text('Record demo (1 device only)'),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Text('Switch account'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.bubbleMe,
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
                color: AppTheme.gradientStart,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Scribble',
            onPressed: _openScribble,
            color: Colors.white,
          ),
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