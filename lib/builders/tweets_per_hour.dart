import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

// == Tweets Per Hour chart ===
Widget buildTweetsPerHourChart(dynamic data) {
  final rows = ensureListOfMap(data);
  final pts = <Offset>[];
  int maxHour = 0; num maxVal = 0;
  for (final r in rows) {
    final h = i_(r['hour']);
    final v = n_(r['tweets']);
    pts.add(Offset(h.toDouble(), v.toDouble()));
    maxHour = h > maxHour ? h : maxHour;
    maxVal = v > maxVal ? v : maxVal;
  }
  return LineChartMini(
    points: pts..sort((a, b) => a.dx.compareTo(b.dx)),
    maxX: (maxHour < 23 ? 23 : maxHour).toDouble(),
    maxY: (maxVal <= 0 ? 1 : maxVal).toDouble(),
    title: 'Tweets per ora',
    xLabelFormatter: (x) => x.toInt().toString(),
    yLabelFormatter: (y) => y.toInt().toString(),
  );
}
