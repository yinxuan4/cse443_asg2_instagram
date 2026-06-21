import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../config/scribble_config.dart';

class ScribbleService {
  ScribbleService() : _db = _databaseRef();

  final DatabaseReference _db;

  static DatabaseReference _databaseRef() {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    ).ref();
  }

  String generateStrokeId(String roomId) =>
      _db.child('rooms/$roomId/strokes').push().key!;

  Future<void> createStroke(
    String roomId,
    String strokeId,
    String userId,
    String color,
  ) async {
    await _db.child('rooms/$roomId/strokes/$strokeId').set({
      'userId': userId,
      'color': color,
      'isActive': true,
      'points': [],
    });
  }

  DatabaseReference strokesRef(String roomId) =>
      _db.child('rooms/$roomId/strokes');

  Future<void> appendPoints(
    String roomId,
    String strokeId,
    List<Offset> points,
  ) {
    final pointMaps = points.map((p) => {'x': p.dx, 'y': p.dy}).toList();
    return _db.child('rooms/$roomId/strokes/$strokeId/points').set(pointMaps);
  }

  Future<void> markStrokeComplete(String roomId, String strokeId) {
    return _db.child('rooms/$roomId/strokes/$strokeId/isActive').set(false);
  }

  Future<void> clearCanvas(String roomId) {
    return _db.child('rooms/$roomId/strokes').remove();
  }

  Stream<DatabaseEvent> listenToStrokes(String roomId) =>
      _db.child('rooms/$roomId/strokes').onValue;
}
