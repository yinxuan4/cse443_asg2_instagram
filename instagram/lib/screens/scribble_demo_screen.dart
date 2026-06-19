import 'package:flutter/material.dart';

import '../widgets/scribble_canvas.dart';

/// Single-device demo: two panels (userA / userB) sync through Firebase.
class ScribbleDemoScreen extends StatelessWidget {
  const ScribbleDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Split Demo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Simulates 2 users on one screen for video recording. Real use: User A on one device, User B on another.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: ScribbleCanvas(userId: 'userA', embedded: true),
                  ),
                ),
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: ScribbleCanvas(userId: 'userB', embedded: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
