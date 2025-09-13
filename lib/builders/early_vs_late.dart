import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

/// Barre comparate: Early vs Late (volume + avg_engagement)
Widget buildEarlyVsLateBars(dynamic data) {
  final rows = ensureListOfMap(data);
  num eVol = 0, lVol = 0, eAvg = 0, lAvg = 0;
  for (final r in rows) {
    final phase = s_(r['phase']).toLowerCase();
    if (phase == 'early') { eVol = n_(r['tweets']); eAvg = n_(r['avg_engagement']); }
    if (phase == 'late')  { lVol = n_(r['tweets']); lAvg = n_(r['avg_engagement']); }
  }
  final maxVol = (eVol > lVol ? eVol : lVol); 
  final maxAvg = (eAvg > lAvg ? eAvg : lAvg);

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            LegendSwatch(color: Colors.indigo, label: 'Tweets'),
            SizedBox(width: 12),
            LegendSwatch(color: Colors.teal, label: 'Avg engagement'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Early'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: SimpleBar(value: eVol.toDouble(), max: (maxVol <= 0 ? 1 : maxVol).toDouble(), color: Colors.indigo, label: eVol.toInt().toString())),
                          const SizedBox(width: 10),
                          Expanded(child: SimpleBar(value: eAvg.toDouble(), max: (maxAvg <= 0 ? 1 : maxAvg).toDouble(), color: Colors.teal,   label: eAvg.toStringAsFixed(1))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text('Late'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: SimpleBar(value: lVol.toDouble(), max: (maxVol <= 0 ? 1 : maxVol).toDouble(), color: Colors.indigo, label: lVol.toInt().toString())),
                          const SizedBox(width: 10),
                          Expanded(child: SimpleBar(value: lAvg.toDouble(), max: (maxAvg <= 0 ? 1 : maxAvg).toDouble(), color: Colors.teal,   label: lAvg.toStringAsFixed(1))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
