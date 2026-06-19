import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../config/scribble_config.dart';
import '../services/scribble_service.dart';

class ScribbleCanvas extends StatefulWidget {
  final String userId;

  const ScribbleCanvas({super.key, required this.userId});

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

  StreamSubscription<DatabaseEvent>? _strokeSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToRemoteStrokes();
  }

  @override
  void dispose() {
    _strokeSubscription?.cancel();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _activeStrokeId = _scribbleService.generateStrokeId(_roomId);
    _localPoints = [details.localPosition];
    _scribbleService.createStroke(
      _roomId,
      _activeStrokeId!,
      widget.userId,
      _color,
    );
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _localPoints.add(details.localPosition);
    setState(() {});

    final now = DateTime.now();
    if (now.difference(_lastSentTime).inMilliseconds > 30) {
      _scribbleService.appendPoints(_roomId, _activeStrokeId!, _localPoints);
      _lastSentTime = now;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeStrokeId == null) return;

    _scribbleService.appendPoints(_roomId, _activeStrokeId!, _localPoints);
    _scribbleService.markStrokeComplete(_roomId, _activeStrokeId!);
    _activeStrokeId = null;
    _localPoints = [];
    setState(() {});
  }

  void _subscribeToRemoteStrokes() {
    _strokeSubscription =
        _scribbleService.listenToStrokes(_roomId).listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final updatedRemoteStrokes = <String, List<Offset>>{};

      data.forEach((strokeId, strokeData) {
        final strokeMap = strokeData as Map<dynamic, dynamic>;
        final senderId = strokeMap['userId'];
        if (senderId == widget.userId) return;

        final rawPoints = strokeMap['points'] as List<dynamic>? ?? [];
        final points = rawPoints
            .map(
              (p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ),
            )
            .toList();

        updatedRemoteStrokes[strokeId as String] = points;
      });

      setState(() {
        _remoteStrokes
          ..clear()
          ..addAll(updatedRemoteStrokes);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
            const Divider(height: 1),
            Expanded(
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: ScribblePainter(_localPoints, _remoteStrokes),
                  size: Size.infinite,
                ),
              ),
            ),
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
