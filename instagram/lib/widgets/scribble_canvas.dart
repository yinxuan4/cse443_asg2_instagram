import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../config/scribble_config.dart';
import '../services/scribble_service.dart';

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
  final String _color = '#2196F3';

  String? _activeStrokeId;
  List<Offset> _localPoints = [];
  final Map<String, List<Offset>> _remoteStrokes = {};
  DateTime _lastSentTime = DateTime.now();
  bool _strokeReady = false;
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

  List<Offset> _parsePoints(dynamic rawPoints) {
    if (rawPoints == null) return [];

    if (rawPoints is List) {
      return rawPoints
          .map(
            (p) => Offset(
              (p['x'] as num).toDouble(),
              (p['y'] as num).toDouble(),
            ),
          )
          .toList();
    }

    if (rawPoints is Map) {
      final sortedKeys = rawPoints.keys.map((k) => k.toString()).toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      return sortedKeys
          .map((key) {
            final p = rawPoints[key] as Map<dynamic, dynamic>;
            return Offset(
              (p['x'] as num).toDouble(),
              (p['y'] as num).toDouble(),
            );
          })
          .toList();
    }

    return [];
  }

  Future<void> _onPanStart(DragStartDetails details) async {
    _activeStrokeId = _scribbleService.generateStrokeId(_roomId);
    _localPoints = [details.localPosition];
    _strokeReady = false;
    _lastSentTime = DateTime.now();
    setState(() {});

    try {
      await _scribbleService.createStroke(
        _roomId,
        _activeStrokeId!,
        widget.userId,
        _color,
      );
      _strokeReady = true;
      await _scribbleService.appendPoints(
        _roomId,
        _activeStrokeId!,
        _localPoints,
      );
      if (mounted) setState(() => _status = 'Connected — drawing as ${widget.userId}');
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Firebase error: $e');
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeStrokeId == null || !_strokeReady) return;

    _localPoints.add(details.localPosition);
    setState(() {});

    final now = DateTime.now();
    if (now.difference(_lastSentTime).inMilliseconds > 30) {
      _scribbleService.appendPoints(_roomId, _activeStrokeId!, _localPoints);
      _lastSentTime = now;
    }
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_activeStrokeId == null || !_strokeReady) return;

    await _scribbleService.appendPoints(_roomId, _activeStrokeId!, _localPoints);
    await _scribbleService.markStrokeComplete(_roomId, _activeStrokeId!);
    _activeStrokeId = null;
    _strokeReady = false;
    _localPoints = [];
    setState(() {});
  }

  void _subscribeToRemoteStrokes() {
    _strokeSubscription = _scribbleService
        .listenToStrokes(_roomId)
        .listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) {
          if (mounted) setState(() => _status = 'Connected — waiting for strokes');
          return;
        }

        final updatedRemoteStrokes = <String, List<Offset>>{};

        data.forEach((strokeId, strokeData) {
          final strokeMap = strokeData as Map<dynamic, dynamic>;
          final senderId = strokeMap['userId']?.toString();
          if (senderId == widget.userId) return;

          updatedRemoteStrokes[strokeId.toString()] =
              _parsePoints(strokeMap['points']);
        });

        if (mounted) {
          setState(() {
            _remoteStrokes
              ..clear()
              ..addAll(updatedRemoteStrokes);
            _status = 'Connected — ${updatedRemoteStrokes.length} remote stroke(s)';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _status = 'Firebase denied: $error');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvas = GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: ScribblePainter(_localPoints, _remoteStrokes),
        size: Size.infinite,
      ),
    );

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey.shade200,
            child: Text(
              widget.userId,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: canvas),
        ],
      );
    }

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Live Scribble',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    widget.userId,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Both users must open Scribble on their device. '
                'You draw blue; the other user sees red.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _status.contains('error') || _status.contains('denied')
                      ? Colors.red
                      : Colors.green.shade700,
                  fontSize: 11,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: canvas),
          ],
        ),
      ),
    );
  }
}

class ScribblePainter extends CustomPainter {
  final List<Offset> localPoints;
  final Map<String, List<Offset>> remoteStrokes;

  ScribblePainter(this.localPoints, this.remoteStrokes);

  @override
  void paint(Canvas canvas, Size size) {
    _drawPath(
      canvas,
      localPoints,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    for (final points in remoteStrokes.values) {
      _drawPath(
        canvas,
        points,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant ScribblePainter oldDelegate) => true;
}
