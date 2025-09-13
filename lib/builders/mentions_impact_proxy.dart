import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

/// “Andamento” a barre per 4 combinazioni: verified×mentions
/// Disposizione: 2 righe — sopra Verified, sotto Unverified.
/// In ogni cella: due barre (Volume e Avg engagement).
Widget buildMentionsImpactTrend(dynamic data) {
  final rows = ensureListOfMap(data);

  // indicizza per coppia (verified, has_mentions)
  final Map<String, Map<String, dynamic>> byKey = {};
  for (final r in rows) {
    final v = (r['verified'] == true);
    final m = (r['has_mentions'] == true);
    byKey['${v ? 1 : 0}|${m ? 1 : 0}'] = r;
  }
  Map<String, dynamic>? getRow(bool verified, bool mentions) =>
      byKey['${verified ? 1 : 0}|${mentions ? 1 : 0}'];

  // scale comuni
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
              // Row header opzionali per le colonne
              const SizedBox(height: 6),
              // ─── RIGA 1: VERIFIED ───
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

              // ─── RIGA 2: UNVERIFIED ───
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
