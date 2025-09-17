import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';

// == Device × Verified histograms ===
Widget buildDeviceVerifiedHistos(dynamic data) {
  final rows = ensureListOfMap(data);

  final byDevice = <String, Map<bool, num>>{};
  num maxVol = 1;
  for (final r in rows) {
    final dev = s_(r['device_norm']);
    final ver = r['verified'] == true;
    final vol = n_(r['volume']);
    byDevice.putIfAbsent(dev, () => {true: 0, false: 0});
    byDevice[dev]![ver] = (byDevice[dev]![ver] ?? 0) + vol;
    if (byDevice[dev]![ver]! > maxVol) maxVol = byDevice[dev]![ver]!;
  }

  final devices = byDevice.keys.toList()..sort();

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Istogrammi: volume per device × verified',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: const [
            LegendSwatch(color: Colors.blue, label: 'Verified'),
            SizedBox(width: 12),
            LegendSwatch(color: Colors.grey, label: 'Unverified'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, i) {
              final d = devices[i];
              final vTrue = (byDevice[d]![true] ?? 0).toDouble();
              final vFalse = (byDevice[d]![false] ?? 0).toDouble();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          Expanded(child: SimpleBar(value: vTrue,  max: maxVol.toDouble(), color: Colors.blue,  label: vTrue.toInt().toString())),
                          const SizedBox(width: 10),
                          Expanded(child: SimpleBar(value: vFalse, max: maxVol.toDouble(), color: Colors.grey, label: vFalse.toInt().toString())),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
