import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

// == Mentions × Impact trend ===
Widget buildMentionsImpactTrend(dynamic data) {
  final rows = ensureListOfMap(data);

  final Map<String, Map<String, dynamic>> byKey = {};
  for (final r in rows) {
    final v = (r['verified'] == true);
    final m = (r['has_mentions'] == true);
    byKey['${v ? 1 : 0}|${m ? 1 : 0}'] = r;
  }
  Map<String, dynamic>? getRow(bool verified, bool mentions) =>
      byKey['${verified ? 1 : 0}|${mentions ? 1 : 0}'];

  num maxVol = 1;
  num maxAvg = 1;
  for (final r in rows) {
    final vol = n_(r['volume']);
    final avg = n_(r['avg_engagement']);
    if (vol > maxVol) maxVol = vol;
    if (avg > maxAvg) maxAvg = avg;
  }

  Widget cell(String title, Map<String, dynamic>? r) {
    final vol = r == null ? 0.0 : n_(r['volume']).toDouble();
    final avg = r == null ? 0.0 : n_(r['avg_engagement']).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                child: SimpleBar(
                  value: vol,
                  max: maxVol.toDouble(),
                  color: Colors.indigo,
                  label: vol.toInt().toString(),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SimpleBar(
                  value: avg,
                  max: (maxAvg <= 1 ? 1 : maxAvg.toDouble()),
                  color: Colors.teal,
                  label: avg.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 90,
                    child: Text('Verified',
                        style: TextStyle(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.left,
                        ),
                  ),
                  Expanded(child: cell('Mentions', getRow(true, true))),
                  const SizedBox(width: 12),
                  Expanded(child: cell('No mentions', getRow(true, false))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 90,
                    child: Text('Unverified',
                        style: TextStyle(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.left,
                        ),
                  ),
                  Expanded(child: cell('Mentions', getRow(false, true))),
                  const SizedBox(width: 12),
                  Expanded(child: cell('No mentions', getRow(false, false))),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
