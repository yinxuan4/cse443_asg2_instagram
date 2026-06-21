class StrokePoint {
  final double x;
  final double y;

  const StrokePoint({required this.x, required this.y});

  Map<String, double> toMap() => {'x': x, 'y': y};

  factory StrokePoint.fromMap(Map<dynamic, dynamic> map) {
    return StrokePoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}
