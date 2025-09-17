import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

// == Sensitive stats pie ===
Widget buildSensitiveStatsPie(dynamic data) {
  final rows = ensureListOfMap(data);
  num yes = 0, no = 0;
  for (final r in rows) {
    final ps = r['possibly_sensitive'] == true;
    final v = n_(r['tweets']);
    if (ps) { yes += v; } else { no += v; }
  }
  final slices = <PieSlice>[
    PieSlice(label: 'Sensitive', value: yes.toDouble()),
    PieSlice(label: 'Non-sensitive', value: no.toDouble()),
  ];
  return PieChartMini(title: 'Sensitive stats', slices: slices);
}
