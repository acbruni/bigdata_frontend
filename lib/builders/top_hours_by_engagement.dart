import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

// == Top Hours by Engagement trend ===
Widget buildTopHoursTrend(dynamic data) {
  final rows = ensureListOfMap(data);
  rows.sort((a, b) => i_(a['hour']).compareTo(i_(b['hour'])));
  final pts = <Offset>[];
  num maxY = 1; int maxX = 0;
  for (final r in rows) {
    final h = i_(r['hour']);
    final y = n_(r['avg_engagement']);
    pts.add(Offset(h.toDouble(), y.toDouble()));
    if (h > maxX) maxX = h;
    if (y > maxY) maxY = y;
  }
  return LineChartMini(
    points: pts,
    maxX: (maxX < 23 ? 23 : maxX).toDouble(),
    maxY: (maxY <= 0 ? 1 : maxY).toDouble(),
    title: 'Avg engagement per ora',
    xLabelFormatter: (x) => x.toInt().toString(),
    yLabelFormatter: (y) => y.toStringAsFixed(1),
  );
}
