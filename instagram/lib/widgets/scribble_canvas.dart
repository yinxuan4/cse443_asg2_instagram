import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../config/scribble_config.dart';
import '../config/user_config.dart';
import '../models/stroke_data.dart';
import '../services/scribble_service.dart';
import '../theme/app_theme.dart';

class ScribbleCanvas extends StatefulWidget {
  final String userId;
  final bool embedded;

  const ScribbleCanvas({
    super.key,
    required this.userId,
    this.embedded = false,
  });

  @override
  State<ScribbleCanvas> createState() => _ScribbleCanvasState();
}

class _ScribbleCanvasState extends State<ScribbleCanvas> {
  final ScribbleService _scribbleService = ScribbleService();
  final String _roomId = kScribbleRoomId;
  final String _color = '#8B5CF6';

  final Map<String, StrokeData> _allStrokes = {};
  String? _activeStrokeId;
  DateTime _lastSentTime = DateTime.now();
  String _status = 'Connecting...';

  StreamSubscription<DatabaseEvent>? _strokeSubscription;

  @override
  void initState() {
    super.initState();
    _scribbleService.strokesRef(_roomId).keepSynced(true);
    _subscribeToRemoteStrokes();
  }

  @override
  void dispose() {
    _strokeSubscription?.cancel();
    super.dispose();
  }

  int _partnerStrokeCount() =>
      _allStrokes.values.where((s) => s.authorId != widget.userId).length;

  void _updateStatus() {
    final partnerCount = _partnerStrokeCount();
    if (_status.contains('error') ||
        _status.contains('denied') ||
        _status.contains('failed')) {
      return;
    }
    _status = partnerCount == 0
        ? 'Ready to draw'
        : '$partnerCount stroke(s) from partner';
  }

  void _onPanStart(DragStartDetails details) {
    final strokeId = _scribbleService.generateStrokeId(_roomId);
    _activeStrokeId = strokeId;
    _lastSentTime = DateTime.now();

    _allStrokes[strokeId] = StrokeData(
      id: strokeId,
      authorId: widget.userId,
      color: AppTheme.strokeLocal,
      points: [details.localPosition],
    );
    setState(() => _status = 'Live — ${displayNameFor(widget.userId)}');

    _scribbleService
        .createStroke(_roomId, strokeId, widget.userId, _color)
        .then((_) {
      _scribbleService.appendPoints(
        _roomId,
        strokeId,
        _allStrokes[strokeId]?.points ?? [],
      );
    }).catchError((e) {
      if (mounted) setState(() => _status = 'Firebase error: $e');
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeStrokeId == null) return;

    final stroke = _allStrokes[_activeStrokeId];
    if (stroke == null) return;

    stroke.points.add(details.localPosition);
    setState(() {});

    final now = DateTime.now();
    if (now.difference(_lastSentTime).inMilliseconds > 30) {
      _scribbleService.appendPoints(_roomId, _activeStrokeId!, stroke.points);
      _lastSentTime = now;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeStrokeId == null) return;

    final strokeId = _activeStrokeId!;
    final stroke = _allStrokes[strokeId];
    if (stroke != null) {
      _scribbleService.appendPoints(_roomId, strokeId, stroke.points);
      _scribbleService.markStrokeComplete(_roomId, strokeId);
    }

    _activeStrokeId = null;
    setState(() => _updateStatus());
  }

  Future<void> _clearCanvas() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bubbleOther,
        title: const Text('Clear canvas?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This removes all scribbles for everyone in this chat room.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: AppTheme.bubbleMe)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _scribbleService.clearCanvas(_roomId);
      setState(() {
        _allStrokes.clear();
        _activeStrokeId = null;
        _status = 'Canvas cleared';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Clear failed: $e');
    }
  }

  void _subscribeToRemoteStrokes() {
    _strokeSubscription = _scribbleService
        .listenToStrokes(_roomId)
        .listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) {
          if (mounted) {
            setState(() {
              _allStrokes.clear();
              _activeStrokeId = null;
              _status = 'Ready to draw';
            });
          }
          return;
        }

        for (final entry in data.entries) {
          final strokeId = entry.key.toString();
          // Keep the in-progress local stroke — don't overwrite with slower Firebase echo.
          if (strokeId == _activeStrokeId) continue;

          final strokeMap = entry.value as Map<dynamic, dynamic>;
          _allStrokes[strokeId] = StrokeData.fromMap(
            strokeId,
            strokeMap,
            myUserId: widget.userId,
          );
        }

        if (mounted) {
          setState(() => _updateStatus());
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _status = 'Firebase denied: $error');
        }
      },
    );
  }

  Widget _buildCanvasArea() {
    return Container(
      margin: widget.embedded
          ? const EdgeInsets.all(6)
          : const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.canvasBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bubbleMe.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: ScribblePainter(_allStrokes),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Widget leading,
    required String title,
    required String subtitle,
    required List<Widget> trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient,
        border: Border(
          bottom: BorderSide(color: AppTheme.bubbleMe.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return ColoredBox(
        color: AppTheme.scaffoldBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              leading: const SizedBox(width: 8),
              title: displayNameFor(widget.userId),
              subtitle: widget.userId,
              trailing: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Clear canvas',
                  onPressed: _clearCanvas,
                  color: Colors.white70,
                ),
              ],
            ),
            Expanded(child: _buildCanvasArea()),
          ],
        ),
      );
    }

    return Material(
      color: AppTheme.scaffoldBg,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: 'Live Scribble',
              subtitle: 'You: ${displayNameFor(widget.userId)}',
              trailing: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  tooltip: 'Clear canvas',
                  onPressed: _clearCanvas,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _LegendDot(color: AppTheme.strokeLocal, label: 'You'),
                  const SizedBox(width: 16),
                  _LegendDot(color: AppTheme.strokeRemote, label: 'Partner'),
                  const Spacer(),
                  Text(
                    _status,
                    style: TextStyle(
                      color: _status.contains('error') ||
                              _status.contains('denied') ||
                              _status.contains('failed')
                          ? Colors.redAccent
                          : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildCanvasArea()),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class ScribblePainter extends CustomPainter {
  final Map<String, StrokeData> strokes;

  ScribblePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.canvasBg,
    );

    for (final stroke in strokes.values) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScribblePainter oldDelegate) => true;
}
