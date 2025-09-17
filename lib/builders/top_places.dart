import 'package:bigdata_natural_disaster/builders/builder_utils.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

// == Top Places map-like ===
Widget buildTopPlacesMapLike(dynamic data) => TopPlaces(data: data);

class TopPlaces extends StatefulWidget {
  final dynamic data;
  final int maxPoints;
  const TopPlaces({super.key, required this.data, this.maxPoints = 20});

  @override
  State<TopPlaces> createState() => _TopPlacesState();
}

class _TopPlacesState extends State<TopPlaces> {
  late final MapZoomPanBehavior _zoomPan;

  @override
  void initState() {
    super.initState();
    _zoomPan = MapZoomPanBehavior(
      enablePanning: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true, 
      minZoomLevel: 1,
      maxZoomLevel: 12,
      zoomLevel: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = ensureListOfMap(widget.data);
    final markers = <_PlaceMarker>[];
    for (final r in rows) {
      final place = s_(r['place']).trim();
      final count = n_(r['tweets']).toDouble();
      if (place.isEmpty || count <= 0) continue;
      final latLng = _lookupLatLng(place);
      if (latLng != null) {
        markers.add(_PlaceMarker(name: _titleCase(place), latLng: latLng, count: count));
      }
    }
    markers.sort((a, b) => b.count.compareTo(a.count));
    final pts = markers.take(widget.maxPoints).toList();

    if (pts.isEmpty) {
      return const Center(child: Text('No places to show'));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.white, 
        child: SfMaps(
          layers: [
            MapShapeLayer(
              source: MapShapeSource.asset(
                'assets/world_map.json',
                shapeDataField: 'name', 
              ),
              color: Colors.black,       
              strokeColor: Colors.white, 
              strokeWidth: 0.6,
              zoomPanBehavior: _zoomPan,
              initialMarkersCount: pts.length,
              markerBuilder: (context, index) {
                final m = pts[index];
                return MapMarker(
                  latitude: m.latLng.latitude,
                  longitude: m.latLng.longitude,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () {
                      _zoomPan.focalLatLng = m.latLng;
                      _zoomPan.zoomLevel = (_zoomPan.zoomLevel < 4)
                          ? 4
                          : (_zoomPan.zoomLevel + 1).clamp(1, 12).toDouble();
                      setState(() {});
                    },
                    child: _YellowDotWithLabel(
                      title: m.name,
                      subtitle: '${m.count.toInt()}',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _YellowDotWithLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _YellowDotWithLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceMarker {
  final String name;
  final MapLatLng latLng;
  final double count;
  _PlaceMarker({required this.name, required this.latLng, required this.count});
}

MapLatLng? _lookupLatLng(String raw) {
  final norm = _normPlace(raw);

  if (_geoIndex.containsKey(norm)) return _geoIndex[norm]!;
  final parts = norm.split(RegExp(r'\s*,\s*'));
  if (parts.isNotEmpty && _geoIndex.containsKey(parts.first)) {
    return _geoIndex[parts.first]!;
  }
  for (final key in _geoIndex.keys.toList()..sort((a, b) => b.length.compareTo(a.length))) {
    if (norm.contains(key)) return _geoIndex[key]!;
  }
  return null;
}
String _normPlace(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9,\s]+'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
String _titleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1).toLowerCase()))
    .join(' ');
final Map<String, MapLatLng> _geoIndex = {
  'dallas': MapLatLng(32.7767, -96.7970),
  'houston': MapLatLng(29.7604, -95.3698),
  'austin': MapLatLng(30.2672, -97.7431),
  'san antonio': MapLatLng(29.4241, -98.4936),
  'corpus christi': MapLatLng(27.8006, -97.3964),
  'galveston': MapLatLng(29.3013, -94.7977),
  'new orleans': MapLatLng(29.9511, -90.0715),
  'seattle': MapLatLng(47.6062, -122.3321),
  'greenland': MapLatLng(64.1835, -51.7216),
  'yakutsk': MapLatLng(62.0355, 129.6755),
  'belem': MapLatLng(-1.4558, -48.4902),
  'harare': MapLatLng(-17.8292, 31.0522),
  'delhi': MapLatLng(28.6139, 77.2090),
  'brisbane': MapLatLng(-27.4698, 153.0251),
  'london': MapLatLng(51.5074, -0.1278),
  'paris': MapLatLng(48.8566, 2.3522),
  'madrid': MapLatLng(40.4168, -3.7038),
  'rome': MapLatLng(41.9028, 12.4964),
  'berlin': MapLatLng(52.5200, 13.4050),
  'tokyo': MapLatLng(35.6762, 139.6503),
  'osaka': MapLatLng(34.6937, 135.5023),
  'beijing': MapLatLng(39.9042, 116.4074),
  'shanghai': MapLatLng(31.2304, 121.4737),
  'singapore': MapLatLng(1.3521, 103.8198),
  'sydney': MapLatLng(-33.8688, 151.2093),
  'melbourne': MapLatLng(-37.8136, 144.9631),
  'rio de janeiro': MapLatLng(-22.9068, -43.1729),
  'sao paulo': MapLatLng(-23.5558, -46.6396),
  'mexico city': MapLatLng(19.4326, -99.1332),
  'bogota': MapLatLng(4.7110, -74.0721),
  'buenos aires': MapLatLng(-34.6037, -58.3816),
  'cairo': MapLatLng(30.0444, 31.2357),
  'johannesburg': MapLatLng(-26.2041, 28.0473),
  'nairobi': MapLatLng(-1.2921, 36.8219),
  'moscow': MapLatLng(55.7558, 37.6173),
  'istanbul': MapLatLng(41.0082, 28.9784),
  'tehran': MapLatLng(35.6892, 51.3890),
  'dubai': MapLatLng(25.2048, 55.2708),
  'toronto': MapLatLng(43.6532, -79.3832),
  'montreal': MapLatLng(45.5019, -73.5674),
  'new york': MapLatLng(40.7128, -74.0060),
  'boston': MapLatLng(42.3601, -71.0589),
  'chicago': MapLatLng(41.8781, -87.6298),
  'los angeles': MapLatLng(34.0522, -118.2437),
  'miami': MapLatLng(25.7617, -80.1918),
};