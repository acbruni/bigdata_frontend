import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// === API ===
const String API_BASE = 'http://127.0.0.1:8000';
const String EP_LATEST = '/model/latest_metrics';

class LatestMetricsPage extends StatefulWidget {
  const LatestMetricsPage({super.key});
  @override
  State<LatestMetricsPage> createState() => _LatestMetricsPageState();
}

class _LatestMetricsPageState extends State<LatestMetricsPage> {
  bool _loading = false;
  String? _error;

  // metrics
  String _acc = '—';
  String _macroF1 = '—';
  Map<String, dynamic> _params = const {};
  List<String> _labels = const [];
  List<List<int>> _cm = const [];
  List<Map<String, dynamic>> _perClassRows = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$API_BASE$EP_LATEST');
      final r = await http.get(uri);
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception('HTTP ${r.statusCode}: ${r.body}');
      }
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final metrics = (j['metrics'] ?? {}) as Map<String, dynamic>;
      final cm = (metrics['confusion_matrix'] ?? {}) as Map<String, dynamic>;
      final labels = (cm['labels'] as List<dynamic>? ?? []).cast<String>();
      final tableDyn = (cm['as_table'] as List<dynamic>? ?? []);
      final table = tableDyn
          .map<List<int>>(
            (row) => (row as List<dynamic>).map((e) => (e as num).toInt()).toList(),
          )
          .toList();

      // per-class → righe tabella
      final perClassRaw = (metrics['per_class'] ?? {}) as Map<String, dynamic>;
      final rows = <Map<String, dynamic>>[];
      perClassRaw.forEach((k, v) {
        final m = (v as Map<String, dynamic>);
        rows.add({
          'class': k,
          'precision': (m['precision'] ?? 0.0) as num,
          'recall': (m['recall'] ?? 0.0) as num,
          'f1': (m['f1'] ?? 0.0) as num,
          'TP': (m['TP'] ?? 0) as num,
          'FP': (m['FP'] ?? 0) as num,
        });
      });

      setState(() {
        _acc = ((metrics['accuracy'] ?? 0.0) as num).toStringAsFixed(4);
        _macroF1 = ((metrics['macro_f1'] ?? 0.0) as num).toStringAsFixed(4);
        _params = (j['params'] ?? {}) as Map<String, dynamic>;
        _labels = labels;
        _cm = table;
        _perClassRows = rows;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- UI helpers ----------
  Widget _glass({required Widget child, EdgeInsetsGeometry pad = const EdgeInsets.all(18)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: pad,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _kpiBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          ),
          child: Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 15)),
        ),
      ],
    );
  }

  Widget _paramField(String label, String value) {
    return _kpiBox(label, value);
  }

  Widget _refreshButton() {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _fetch,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Refresh'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,     // sfondo bianco
        foregroundColor: Colors.black,     // testo/icone nere
        elevation: 0,
        shape: const StadiumBorder(),
        side: const BorderSide(color: Colors.black12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _perClassTable() {
    if (_perClassRows.isEmpty) {
      return _kpiBox('Per-class', '—');
    }
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 10),
            child: Text('Per-class', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          DataTable(
            columnSpacing: 28,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w700),
            columns: const [
              DataColumn(label: Text('Class')),
              DataColumn(label: Text('Precision')),
              DataColumn(label: Text('Recall')),
              DataColumn(label: Text('F1')),
              DataColumn(label: Text('TP')),
              DataColumn(label: Text('FP')),
            ],
            rows: _perClassRows.map((r) {
              String f(num v) => (v).toStringAsFixed(4);
              return DataRow(
                cells: [
                  DataCell(Text(r['class'] as String)),
                  DataCell(Text(f(r['precision'] as num))),
                  DataCell(Text(f(r['recall'] as num))),
                  DataCell(Text(f(r['f1'] as num))),
                  DataCell(Text((r['TP'] as num).toString())),
                  DataCell(Text((r['FP'] as num).toString())),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _cmHeatmap() {
    if (_labels.isEmpty || _cm.isEmpty) {
      return _glass(child: const Text('Confusion matrix not available'));
    }
    // la scatola intera è ridimensionabile senza overflow
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 10),
            child: Text('Confusion matrix', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          LayoutBuilder(builder: (context, c) {
            // dimensione desiderata del quadrato heatmap
            const desired = 420.0;
            // FittedBox scalerà se maxW < desired
            return Center(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: _ConfusionMatrixView(
                  labels: _labels,
                  table: _cm,
                  side: desired,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Text('Latest Metrics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _glass(
                  pad: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Header + refresh
                Row(
                  children: [
                    const Expanded(
                      child: Text('Model performance metrics from the latest training run.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
                    ),
                    _refreshButton(),
                  ],
                ),
                const SizedBox(height: 18),
                // KPI principali
                Row(
                  children: [
                    Expanded(child: _kpiBox('Accuracy', _acc)),
                    const SizedBox(width: 14),
                    Expanded(child: _kpiBox('Macro F1', _macroF1)),
                  ],
                ),
                const SizedBox(height: 18),

                // Layout responsivo: a 2 colonne se c'è spazio, altrimenti in colonna
                LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth >= 1100;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Colonna sinistra: parametri + per-class
                          Expanded(
                            child: Column(
                              children: [
                                _glass(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6, bottom: 10),
                                        child: Text('Params',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800, fontSize: 16)),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(child: _paramField('Files limit', '${_params['files_limit'] ?? '—'}')),
                                          const SizedBox(width: 14),
                                          Expanded(child: _paramField('Min df tokens', '${_params['min_df_tokens'] ?? '—'}')),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(child: _paramField('Vocabulary size', '${_params['vocab_size'] ?? '—'}')),
                                          const SizedBox(width: 14),
                                          Expanded(child: _paramField('Shuffle partitions used', '${_params['shuffle_partitions_used'] ?? '—'}')),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(child: _paramField('Dynamic shuffle', '${_params['dynamic_shuffle'] ?? '—'}')),
                                          const SizedBox(width: 14),
                                          Expanded(child: _paramField('Binary cv', '${_params['binary_cv'] ?? '—'}')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _perClassTable(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          // Colonna destra: heatmap
                          Expanded(child: _cmHeatmap()),
                        ],
                      );
                    }
                    // Stretto: tutto in colonna
                    return Column(
                      children: [
                        _glass(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 6, bottom: 10),
                                child: Text('Params',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 16)),
                              ),
                              Row(
                                children: [
                                  Expanded(child: _paramField('Files limit', '${_params['files_limit'] ?? '—'}')),
                                  const SizedBox(width: 14),
                                  Expanded(child: _paramField('Min df tokens', '${_params['min_df_tokens'] ?? '—'}')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _paramField('Vocabulary size', '${_params['vocab_size'] ?? '—'}')),
                                  const SizedBox(width: 14),
                                  Expanded(child: _paramField('Shuffle partitions used', '${_params['shuffle_partitions_used'] ?? '—'}')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _paramField('Dynamic shuffle', '${_params['dynamic_shuffle'] ?? '—'}')),
                                  const SizedBox(width: 14),
                                  Expanded(child: _paramField('Binary cv', '${_params['binary_cv'] ?? '—'}')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _perClassTable(),
                        const SizedBox(height: 18),
                        _cmHeatmap(),
                      ],
                    );
                  },
                ),

                if (_loading) ...[
                  const SizedBox(height: 18),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Text('Error: $_error',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
          ),
        ),
      );
  }
}

/// View componibile della confusion matrix (etichetta top/left + griglia)
class _ConfusionMatrixView extends StatelessWidget {
  final List<String> labels;
  final List<List<int>> table;
  final double side; // lato dell'area quadrata della griglia

  const _ConfusionMatrixView({
    required this.labels,
    required this.table,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    final double cell = side / n;
    final int maxVal = table.expand((r) => r).fold<int>(0, (m, v) => v > m ? v : m);

    Color colorFor(int v) {
      if (maxVal <= 0) return Colors.white;
      final t = (v / maxVal).clamp(0.0, 1.0);
      return Color.lerp(Colors.white, Colors.orange, t)!;
    }

    // Top labels (colonne) + left labels (righe) + griglia dentro uno Stack
    final topH = 28.0;
    final leftW = 92.0;
    final totalW = leftW + side + 8;
    final totalH = topH + side + 8;

    return Container(
      width: totalW,
      height: totalH,
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // Top header
          Positioned(
            left: leftW,
            top: 0,
            right: 0,
            height: topH,
            child: Row(
              children: List.generate(n, (c) {
                return SizedBox(
                  width: cell,
                  child: Center(
                    child: Text(
                      _ellipsis(labels[c], 8),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ),
          ),
          // Left header
          Positioned(
            left: 0,
            top: topH,
            width: leftW,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(n, (r) {
                return SizedBox(
                  height: cell,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _ellipsis(labels[r], 10),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ),
          ),
          // Grid
          Positioned(
            left: leftW,
            top: topH,
            width: side,
            height: side,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: n * n,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: n,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, idx) {
                  final r = idx ~/ n;
                  final c = idx % n;
                  final v = table[r][c];
                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorFor(v).withOpacity(r == c ? 0.95 : 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: r == c ? Colors.amber : Colors.black12,
                        width: r == c ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        v.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ellipsis(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max - 1) + '…';
  }
}