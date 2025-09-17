import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

// == Geo-Temporal Hotspots timelines ===
Widget buildGeoTemporalHotspotsTimelines(dynamic data) {
  final rows = ensureListOfMap(data);

  int pickHour(Map<String, dynamic> r) {
    if (r.containsKey('hour_of_day')) {
      return i_(r['hour_of_day']).clamp(0, 23);
    }
    final iso = s_(r['hour']);
    final dt = DateTime.tryParse(iso);
    if (dt != null) return dt.toUtc().hour;
    return i_(r['hour']).clamp(0, 23);
  }

  final byPlace = <String, List<num>>{};
  for (final raw in rows) {
    final r = Map<String, dynamic>.from(raw);
    final place = s_(r['place']);
    final hour = pickHour(r);
    final vol  = n_(r['volume']);
    byPlace.putIfAbsent(place, () => List<num>.filled(24, 0));
    byPlace[place]![hour] = byPlace[place]![hour] + vol;
  }

  final places = byPlace.keys.toList()
    ..sort((a, b) {
      num sum(List<num> xs) => xs.fold<num>(0, (s, v) => s + v);
      return sum(byPlace[b]!).compareTo(sum(byPlace[a]!));
    });

  return Padding(
    padding: const EdgeInsets.all(16),
    child: ListView.separated(
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = places[i];
        final vals = byPlace[p]!;
        final maxY = vals.fold<num>(0, (m, v) => v > m ? v : m).toDouble();
        final pts = [for (int h = 0; h < 24; h++) Offset(h.toDouble(), vals[h].toDouble())];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SizedBox(
              height: 140,
              child: LineChartMini(
                points: pts,
                maxX: 23.0,
                maxY: maxY <= 0 ? 1 : maxY,
                title: null,
                xLabelFormatter: (x) => x.toInt().toString(),
                yLabelFormatter: (y) => y.toInt().toString(),
              ),
            ),
          ],
        );
      },
    ),
  );
}