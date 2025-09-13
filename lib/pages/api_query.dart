import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bigdata_natural_disaster/builders/builder.dart';

// === Config ===
const String API_BASE = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:8000',
);

// === Query Class (icone + tooltip) ===
class QuerySpec {
  final String id;
  final String label;
  final String method; // 'GET' | 'POST'
  final String path;
  final Map<String, String>? defaultParams;
  final Widget Function(dynamic data) builder;
  final IconData icon;
  final String hint;

  const QuerySpec({
    required this.id,
    required this.label,
    required this.method,
    required this.path,
    this.defaultParams,
    required this.builder,
    required this.icon,
    required this.hint,
  });
}

final List<QuerySpec> kQueries = [
  QuerySpec(
    id: 'top-viral-post',
    label: 'Top viral post',
    method: 'GET',
    path: '/top-viral-post',
    defaultParams: const {'limit': '5'},
    builder: buildTopViralPost,
    icon: Icons.local_fire_department_outlined,
    hint: 'Post with highest engagement',
  ),
  QuerySpec(
    id: 'tweets-per-hour',
    label: 'Tweets per hour',
    method: 'GET',
    path: '/tweets-per-hour',
    builder: buildTweetsPerHourChart,
    icon: Icons.timeline,
    hint: 'Volume of tweets over time',
  ),
  QuerySpec(
    id: 'top-hashtags',
    label: 'Top hashtag',
    method: 'GET',
    path: '/top-hashtags',
    defaultParams: const {'min_len': '1', 'limit': '50'},
    builder: buildTopHashtagsPodium,
    icon: Icons.local_offer_outlined,
    hint: 'Hashtags with highest volume',
  ),
  QuerySpec(
    id: 'top-places',
    label: 'Top places',
    method: 'GET',
    path: '/top-places',
    builder: buildTopPlacesMapLike,
    icon: Icons.place_outlined,
    hint: 'Places with highest tweet volume',
  ),
  QuerySpec(
    id: 'sensitive-stats',
    label: 'Possibly sensitive',
    method: 'GET',
    path: '/sensitive-stats',
    builder: buildSensitiveStatsPie,
    icon: Icons.warning_amber_outlined,
    hint: 'Tweets marked as possibly sensitive',
  ),
  QuerySpec(
    id: 'efficient-hashtags',
    label: 'Efficient hashtag',
    method: 'GET',
    path: '/efficient-hashtags',
    defaultParams: const {'min_uses': '20', 'limit': '100'},
    builder: buildEfficientHashtagsPodium,
    icon: Icons.bolt_outlined,
    hint: 'Hashtags with highest engagement',
  ),
  QuerySpec(
    id: 'geo-temporal-hotspots',
    label: 'Geo temporal hotspot',
    method: 'GET',
    path: '/geo-temporal-hotspots',
    builder: buildGeoTemporalHotspotsTimelines,
    icon: Icons.map_outlined,
    hint: 'Places with spikes in activity',
  ),
  QuerySpec(
    id: 'early-vs-late',
    label: 'Early vs Late',
    method: 'GET',
    path: '/early-vs-late',
    defaultParams: const {'hours': '2'},
    builder: buildEarlyVsLateBars,
    icon: Icons.timelapse_outlined,
    hint: 'Comparison of early vs late tweets',
  ),
  QuerySpec(
    id: 'mentions-impact-proxy',
    label: 'Mentions impact',
    method: 'GET',
    path: '/mentions-impact-proxy',
    builder: buildMentionsImpactTrend,
    icon: Icons.alternate_email,
    hint: 'Impact of mentions on engagement',
  ),
  QuerySpec(
    id: 'top-hours-by-engagement',
    label: 'Top hours by engagement',
    method: 'GET',
    path: '/top-hours-by-engagement',
    defaultParams: const {'min_volume': '20', 'limit': '100'},
    builder: buildTopHoursTrend,
    icon: Icons.access_time,
    hint: 'Hours with highest engagement',
  ),
];

// === Pagina principale ===
class ApiQueryPage extends StatefulWidget {
  const ApiQueryPage({super.key});
  @override
  State<ApiQueryPage> createState() => _ApiQueryPageState();
}

class _ApiQueryPageState extends State<ApiQueryPage> {
  QuerySpec? _selected;
  bool _loading = false;
  String? _error;
  final Map<String, dynamic> _cache = {};
  int _hoveredIndex = -1;

  bool _isCollapsed = true;

  Future<void> _runQuery(QuerySpec spec, {bool forceRefresh = false}) async {
    setState(() {
      _selected = spec;
      _error = null;
      _loading = !(_cache.containsKey(spec.id) && !forceRefresh);
    });
    if (_cache.containsKey(spec.id) && !forceRefresh) return;

    try {
      final uri = Uri.parse('$API_BASE${spec.path}').replace(
        queryParameters:
            (spec.method == 'GET') ? (spec.defaultParams ?? {}) : null,
      );
      final resp =
          (spec.method == 'GET') ? await http.get(uri) : await http.post(uri);

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }
      final data = json.decode(resp.body);
      setState(() {
        _cache[spec.id] = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withOpacity(0.95),
        Colors.black.withOpacity(0.80),
      ],
    );

    // dimensioni sidebar + pulsante circolare
    final double knobSize = 44;
    final double sidebarW = _isCollapsed ? 80.0 : 300.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back , color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Query Interface', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appGradient)),
      ),
      body: Row(
        children: [
          // === Area riservata: sidebar + spazio per il pulsante circolare "attaccato" al bordo
          SizedBox(
            width: sidebarW + knobSize * 0.75, // 1/2 dentro + un piccolo margine
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Sidebar
                Positioned(
                  left: 3,
                  top: 12,
                  bottom: 20,
                  child: AnimatedContainer(
                    width: sidebarW,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    decoration: BoxDecoration(
                      gradient: appGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _SidebarContent(
                        isCollapsed: _isCollapsed,
                        queries: kQueries,
                        selected: _selected,
                        hoveredIndex: _hoveredIndex,
                        cache: _cache,
                        onHoverChange: (i) => setState(() => _hoveredIndex = i),
                        onTapItem: (spec) {
                          if (_isCollapsed) {
                            setState(() => _isCollapsed = false);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _runQuery(spec);
                            });
                          } else {
                            _runQuery(spec);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // Pulsante circolare in stile mockup (mezzo dentro/mezzo fuori)
                Positioned(
                  left: sidebarW - knobSize / 2, // agganciato al bordo destro
                  top: null,
                  bottom: null,
                  height: knobSize,
                  child: _CircleChevronButton(
                    size: knobSize,
                    direction:
                        _isCollapsed ? ChevronDirection.right : ChevronDirection.left,
                    onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                  ),
                ),
              ],
            ),
          ),

          // === Pannello destro ===
          Expanded(
            child: SafeArea(
              child: Builder(
                builder: (context) {
                  if (_selected == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Choose a query and see the results',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 18),
                        ),
                      ),
                    );
                  }
                  final spec = _selected!;
                  final data = _cache[spec.id];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(spec.icon, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    spec.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  _loading ? null : () => _runQuery(spec, forceRefresh: true),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : (_error != null)
                                ? _ErrorView(message: _error!)
                                : (data == null)
                                    ? const Center(child: Text('No data found in cache.'))
                                    : spec.builder(data),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === Pulsante circolare stile mockup ===
enum ChevronDirection { left, right }

class _CircleChevronButton extends StatefulWidget {
  final double size;
  final ChevronDirection direction;
  final VoidCallback onTap;
  const _CircleChevronButton({
    required this.size,
    required this.direction,
    required this.onTap,
  });

  @override
  State<_CircleChevronButton> createState() => _CircleChevronButtonState();
}

class _CircleChevronButtonState extends State<_CircleChevronButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.direction == ChevronDirection.right
        ? Icons.chevron_right
        : Icons.chevron_left;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.grey.shade200,
          shape: const CircleBorder(),
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.25),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Icon(icon, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

// =================== Sidebar content ===================

class _SidebarContent extends StatelessWidget {
  final bool isCollapsed;
  final List<QuerySpec> queries;
  final QuerySpec? selected;
  final int hoveredIndex;
  final Map<String, dynamic> cache;
  final ValueChanged<int> onHoverChange;
  final ValueChanged<QuerySpec> onTapItem;

  const _SidebarContent({
    required this.isCollapsed,
    required this.queries,
    required this.selected,
    required this.hoveredIndex,
    required this.cache,
    required this.onHoverChange,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    // Altezza minima desiderata per item
    const double minItemCollapsed = 44.0;
    const double minItemExpanded  = 46.0; // più basso per evitare scroll

    return LayoutBuilder(
      builder: (context, constraints) {
        final n = queries.length;
        const vGap = 8.0;
        final availableH = constraints.maxHeight;
        final minItem = isCollapsed ? minItemCollapsed : minItemExpanded;

        double calcExtent = (availableH - vGap * (n + 1)) / n;
        final bool fillWithoutScroll = calcExtent >= minItem;
        final double itemExtent = fillWithoutScroll ? calcExtent : minItem;

        final physics = fillWithoutScroll
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics();

        return ListView.separated(
          physics: physics,
          padding: const EdgeInsets.symmetric(vertical: vGap, horizontal: 8),
          itemCount: n,
          separatorBuilder: (_, __) => const SizedBox(height: vGap),
          itemBuilder: (context, i) {
            final spec = queries[i];
            final isSel = selected?.id == spec.id;
            final isHover = hoveredIndex == i;
            final hasData = cache.containsKey(spec.id);

            return MouseRegion(
              onEnter: (_) => onHoverChange(i),
              onExit: (_) => onHoverChange(-1),
              child: SizedBox(
                height: itemExtent,
                child: AnimatedScale(
                  scale: isHover ? 1.04 : (isSel ? 1.05 : 1.0),
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: TextButton(
                    key: ValueKey('btn_${spec.id}_${isCollapsed ? 'c' : 'e'}'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 0),
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      overlayColor: Colors.black12,
                      padding: EdgeInsets.symmetric(
                        horizontal: isCollapsed ? 10 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSel ? Colors.amber : Colors.black12,
                        ),
                      ),
                      alignment:
                          isCollapsed ? Alignment.center : Alignment.centerLeft,
                    ),
                    onPressed: () => onTapItem(spec),
                    child: isCollapsed
                        // Collassata: SOLO icona (niente tick)
                        ? Tooltip(
                            message: spec.hint,
                            waitDuration: const Duration(milliseconds: 250),
                            child: Icon(spec.icon, color: Colors.black87),
                          )
                        // Espansa: icona + testo + tick (se presente)
                        : Row(
                            children: [
                              Tooltip(
                                message: spec.hint,
                                waitDuration:
                                    const Duration(milliseconds: 250),
                                child: Icon(spec.icon, color: Colors.black87),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  spec.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              if (hasData)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.check, size: 16),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// == ERROR VIEW ==
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Flexible(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}