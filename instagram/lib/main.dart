// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const InstagramChatApp());
}

class InstagramChatApp extends StatelessWidget {
  const InstagramChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A0033),
      ),
      home: const ChatScreen(),
    );
  }
}