import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StrokeData {
  final String id;
  final String authorId;
  final Color color;
  final List<Offset> points;

  StrokeData({
    required this.id,
    required this.authorId,
    required this.color,
    List<Offset>? points,
  }) : points = points ?? [];

  static List<Offset> parsePoints(dynamic rawPoints) {
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

  static Color parseColor(String? hex, {required bool isLocal}) {
    if (hex != null && hex.startsWith('#') && hex.length >= 7) {
      final value = int.tryParse(hex.substring(1), radix: 16);
      if (value != null) {
        return Color(0xFF000000 | value);
      }
    }
    return isLocal ? AppTheme.strokeLocal : AppTheme.strokeRemote;
  }

  factory StrokeData.fromMap(
    String id,
    Map<dynamic, dynamic> map, {
    required String myUserId,
  }) {
    final authorId = map['userId']?.toString() ?? '';
    final isLocal = authorId == myUserId;
    return StrokeData(
      id: id,
      authorId: authorId,
      color: parseColor(map['color']?.toString(), isLocal: isLocal),
      points: parsePoints(map['points']),
    );
  }
}
