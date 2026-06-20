import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/scribble_canvas.dart';

/// Single-device demo: two panels (userA / userB) sync through Firebase.
class ScribbleDemoScreen extends StatelessWidget {
  const ScribbleDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Split Demo'),
      ),
      body: Stack(
        children: [
          Container(decoration: AppTheme.gradientBackground()),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Draw on Wei’s side — Shuyi sees it live. For recording on one device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Expanded(
                      child: ScribbleCanvas(userId: 'userA', embedded: true),
                    ),
                    Container(
                      width: 1,
                      color: AppTheme.bubbleMe.withValues(alpha: 0.35),
                    ),
                    const Expanded(
                      child: ScribbleCanvas(userId: 'userB', embedded: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
