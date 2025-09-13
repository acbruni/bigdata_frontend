import 'package:flutter/material.dart';
import 'package:bigdata_natural_disaster/builders/builder_utils.dart';

/// Card stile tweet per /top-viral-post
/// Si aspetta l'output dell'endpoint aggiornato che fornisce:
///  - text_full, engagement, lang, device_norm, created_at,
///  - user_name, user_handle (appiattiti) — ma supporta anche i fallback annidati.
Widget buildTopViralPost(dynamic data) {
  final rows = ensureListOfMap(data);

  String s(dynamic v) => s_(v);

  // Helpers robusti: usano i campi appiattiti, poi fallback annidati / top-level
  String userName(Map<String, dynamic> r) {
    final u = (r['user'] is Map) ? r['user'] as Map : const {};
    return s(r['user_name'] ?? u['name'] ?? r['name'] ?? 'Utente');
  }

  String userHandle(Map<String, dynamic> r) {
    final u = (r['user'] is Map) ? r['user'] as Map : const {};
    return s(r['user_handle'] ??
        u['screen_name'] ??
        u['screenname'] ??
        r['screen_name'] ??
        r['screenname'] ??
        'utente');
  }

  String fullText(Map<String, dynamic> r) {
    if (r.containsKey('text_full') && r['text_full'] != null) {
      return s(r['text_full']);
    }
    final ext = (r['extended_tweet'] is Map) ? r['extended_tweet'] as Map : const {};
    if (ext.containsKey('full_text') && ext['full_text'] != null) {
      return s(ext['full_text']);
    }
    return s(r['text']);
  }

  String createdAt(Map<String, dynamic> r) =>
      s(r['created_at'] ?? r['ts'] ?? r['hour_ts'] ?? '');

  String device0(Map<String, dynamic> r) => s(r['device_norm']);
  String lang0(Map<String, dynamic> r) => s(r['lang']);
  String eng(Map<String, dynamic> r) => n_(r['engagement']).toInt().toString();

  return ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: rows.length,
    separatorBuilder: (_, __) => const SizedBox(height: 14),
    itemBuilder: (context, i) {
      final r = rows[i];

      final name = userName(r);
      final handle = userHandle(r);
      final text = fullText(r);
      final created = createdAt(r);
      final device = device0(r);
      final lang = lang0(r);
      final engagement = eng(r);

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + nome/@handle + created_at a destra
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar "omino" stile immagine mancante
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade400,
                  child: Icon(Icons.person, size: 26, color: Colors.white.withOpacity(0.95)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            '@$handle',
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  created,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Testo COMPLETO (no truncate)
            Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.35),
              softWrap: true,
            ),

            const SizedBox(height: 10),

            // Footer: metriche rapide
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                Text(engagement, style: const TextStyle(color: Colors.black87)),

                const SizedBox(width: 14),
                const Icon(Icons.language, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                Text(lang.isEmpty ? '—' : lang, style: const TextStyle(color: Colors.black87)),

                const SizedBox(width: 14),
                const Icon(Icons.phone_iphone, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    device.isEmpty ? '—' : device,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}