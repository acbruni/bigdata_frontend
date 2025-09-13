import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

/// Podio/cascata: top hashtag
Widget buildTopHashtagsPodium(dynamic data) {
  final rows = ensureListOfMap(data);
  rows.sort((a, b) => n_(b['uses']).compareTo(n_(a['uses'])));
  final maxUses = rows.isEmpty ? 1 : n_(rows.first['uses']);
  return PodiumList(
    items: [
      for (final r in rows)
        PodiumItem(
          label: '#${s_(r['hashtag'])}',
          value: n_(r['uses']).toDouble(),
          barRatio: (n_(r['uses']) / (maxUses == 0 ? 1 : maxUses)).toDouble(),
          subtitle: r.containsKey('avg_engagement')
              ? 'avg_eng: ${n_(r['avg_engagement']).toStringAsFixed(2)}'
              : null,
        )
    ],
  );
}
