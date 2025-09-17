import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

// == Efficient Hashtags podium ===
Widget buildEfficientHashtagsPodium(dynamic data) {
  final rows = ensureListOfMap(data);
  rows.sort((a, b) => n_(b['avg_engagement']).compareTo(n_(a['avg_engagement'])));
  final max = rows.isEmpty ? 1 : n_(rows.first['avg_engagement']);
  return PodiumList(
    title: 'Hashtag efficienti',
    items: [
      for (final r in rows)
        PodiumItem(
          label: '#${s_(r['hashtag'])}',
          value: n_(r['avg_engagement']).toDouble(),
          barRatio: (n_(r['avg_engagement']) / (max == 0 ? 1 : max)).toDouble(),
          subtitle: 'uses: ${i_(r['uses'])}',
        )
    ],
  );
}
