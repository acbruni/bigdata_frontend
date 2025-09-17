// lib/pages/train_panel.dart
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// == API config ==
const String API_BASE = 'http://127.0.0.1:8000';
const String EP_TRAIN = '/model/train';
const Map<String, String> API_HEADERS = {'Content-Type': 'application/json'};

class TrainPanelPage extends StatefulWidget {
  const TrainPanelPage({super.key});
  @override
  State<TrainPanelPage> createState() => _TrainPanelPageState();
}

class _TrainPanelPageState extends State<TrainPanelPage> {
  final _filesLimitCtrl = TextEditingController();
  final _minDfCtrl = TextEditingController();
  final _vocabSizeCtrl = TextEditingController(text: '5000');
  bool _dynamicShuffle = true;
  bool _binaryCv = true;

  bool _isLoading = false;
  bool _hasMetrics = false;

  String _accuracy = '—';
  String _macroF1 = '—';
  String _filesLimitResolved = '—';
  String _shuffleParts = '—';

  List<String> _classLabels = const [];
  Map<String, Map<String, num>> _perClass = const {};
  List<List<int>> _confMatrix = const [];

  @override
  void dispose() {
    _filesLimitCtrl.dispose();
    _minDfCtrl.dispose();
    _vocabSizeCtrl.dispose();
    super.dispose();
  }

  int? _parseIntOrNull(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Uri _buildTrainUri() {
    final params = <String, String>{
      'min_df_tokens': (_parseIntOrNull(_minDfCtrl.text) ?? 10).toString(),
      'vocab_size': (_parseIntOrNull(_vocabSizeCtrl.text) ?? 5000).toString(),
      'dynamic_shuffle': _dynamicShuffle.toString(),
      'binary_cv': _binaryCv.toString(),
    };
    final fl = _parseIntOrNull(_filesLimitCtrl.text);
    if (fl != null) params['files_limit'] = fl.toString();
    return Uri.parse('$API_BASE$EP_TRAIN').replace(queryParameters: params);
  }

  Future<void> _doTrain() async {
    setState(() {
      _isLoading = true;
      _hasMetrics = false;
    });
    try {
      final resp = await http.post(_buildTrainUri(), headers: API_HEADERS);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        final metrics = (j['metrics'] ?? {}) as Map<String, dynamic>;
        final cm = (metrics['confusion_matrix'] ?? {}) as Map<String, dynamic>;
        final labels = (cm['labels'] as List<dynamic>? ?? []).cast<String>();
        final tableDyn = (cm['as_table'] as List<dynamic>? ?? []);
        final table = tableDyn
            .map<List<int>>((row) => (row as List<dynamic>)
                .map((e) => (e as num).toInt())
                .toList())
            .toList();

        final perClassRaw =
            (metrics['per_class'] ?? {}) as Map<String, dynamic>;
        final perClass = <String, Map<String, num>>{};
        perClassRaw.forEach((k, v) {
          perClass[k] = (v as Map<String, dynamic>)
              .map((kk, vv) => MapEntry(kk, (vv as num)));
        });

        setState(() {
          _accuracy = ((metrics['accuracy'] ?? 0.0) as num).toStringAsFixed(4);
          _macroF1 = ((metrics['macro_f1'] ?? 0.0) as num).toStringAsFixed(4);
          _filesLimitResolved = (j['resolved_files_limit'] ?? '—').toString();
          _shuffleParts = (j['shuffle_partitions_used'] ?? '—').toString();

          _classLabels = labels;
          _confMatrix = table;
          _perClass = perClass;
          _hasMetrics = true;
        });
      } else {
        _resetWithError('error ${resp.statusCode}', resp.body);
      }
    } catch (e) {
      _resetWithError('network error', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetWithError(String acc, String macro) {
    setState(() {
      _accuracy = acc;
      _macroF1 = macro.isNotEmpty ? macro : '—';
      _filesLimitResolved = '—';
      _shuffleParts = '—';
      _classLabels = const [];
      _confMatrix = const [];
      _perClass = const {};
      _hasMetrics = false;
    });
  }

  void _doClean() {
    _filesLimitCtrl.clear();
    _minDfCtrl.text = '10';
    _vocabSizeCtrl.text = '5000';
    _dynamicShuffle = true;
    _binaryCv = true;
    _resetWithError('—', '—');
  }

  Widget glassCard({required Widget child, EdgeInsets pad = const EdgeInsets.all(18)}) {
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: child,
        ),
      ),
    );
  }

  OutlineInputBorder _glassBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.9), width: 1),
      );

  Widget glassTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    final b = _glassBorder();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 6, bottom: 6), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withOpacity(0.45),
            enabledBorder: b,
            focusedBorder: b.copyWith(borderSide: BorderSide(color: Colors.black.withOpacity(0.75), width: 1.2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget glassInfoBox({required String label, required String value, TextStyle? valueStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(padding: const EdgeInsets.only(left: 6, bottom: 6), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          ),
          child: Text(value, style: valueStyle ?? const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        ),
      ],
    );
  }

  Widget _gradientButton({required IconData icon, required String label, required VoidCallback? onTap}) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.80)],
    );
    return Opacity(
      opacity: onTap == null ? 0.6 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _darkSwitch({required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchTheme(
      data: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.selected) ? Colors.black : Colors.white),
        trackColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.selected) ? Colors.black54 : Colors.black26),
      ),
      child: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _leftForm() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 16),
          child: Text('Train settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        ),
        Expanded(
          child: glassCard(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  glassTextField(
                    label: 'Files limit (optional)',
                    controller: _filesLimitCtrl,
                    hint: 'Example: 15 (available = 31 / empty = None)',
                    keyboardType: TextInputType.number,
                    icon: Icons.folder_open_outlined,
                  ),
                  const SizedBox(height: 14),
                  glassTextField(
                    label: 'Min df tokens',
                    controller: _minDfCtrl,
                    hint: 'Example: 10',
                    keyboardType: TextInputType.number,
                    icon: Icons.filter_alt_outlined,
                  ),
                  const SizedBox(height: 14),
                  glassTextField(
                    label: 'Vocabulary size *',
                    controller: _vocabSizeCtrl,
                    hint: 'Example: 5000',
                    keyboardType: TextInputType.number,
                    icon: Icons.list_alt_outlined,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Row(children: [
                          const Icon(Icons.shuffle_rounded),
                          const SizedBox(width: 8),
                          const Text('Dynamic shuffle'),
                          const Spacer(),
                          _darkSwitch(value: _dynamicShuffle, onChanged: (v) => setState(() => _dynamicShuffle = v)),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Row(children: [
                          const Icon(Icons.timelapse_outlined),
                          const SizedBox(width: 8),
                          const Text('Binary CV'),
                          const Spacer(),
                          _darkSwitch(value: _binaryCv, onChanged: (v) => setState(() => _binaryCv = v)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _gradientButton(icon: Icons.cleaning_services_outlined, label: 'Clean', onTap: _isLoading ? null : _doClean),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _isLoading
                    ? Row(
                        key: const ValueKey('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Loading...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('idle')),
              ),
            ),
            const SizedBox(width: 12),
            _gradientButton(icon: Icons.science_outlined, label: 'Train', onTap: _isLoading ? null : _doTrain),
          ],
        ),
      ],
    );
  }
  Widget _metricsRight() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 16),
          child: Text('Metrics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        ),
        Expanded(
          child: glassCard(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                      child: glassInfoBox(
                        label: 'Accuracy',
                        value: _hasMetrics ? _accuracy : '—',
                        valueStyle: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: glassInfoBox(
                        label: 'Macro F1',
                        value: _hasMetrics ? _macroF1 : '—',
                        valueStyle: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: glassInfoBox(label: 'Resolved files limit', value: _hasMetrics ? _filesLimitResolved : '—')),
                    const SizedBox(width: 14),
                    Expanded(child: glassInfoBox(label: 'Shuffle partitions used', value: _hasMetrics ? _shuffleParts : '—')),
                  ]),
                  const SizedBox(height: 20),

                  Text('Per-class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.85))),
                  const SizedBox(height: 8),
                  if (_perClass.isEmpty) glassInfoBox(label: '', value: '—') else _PerClassTable(perClass: _perClass),

                  const SizedBox(height: 20),

                  Text('Confusion matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.85))),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    child: Center(
                      child: _ConfusionHeatmap(labels: _classLabels, matrix: _confMatrix),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(child: Padding(padding: const EdgeInsets.all(16), child: _leftForm())),
            Expanded(child: Padding(padding: const EdgeInsets.all(16), child: _metricsRight())),
          ],
        ),
      ),
    );
  }
}
// == TABELLA PER-CLASSE ==
class _PerClassTable extends StatelessWidget {
  final Map<String, Map<String, num>> perClass;
  const _PerClassTable({required this.perClass});

  String _fmt(num v) => (v is int) ? v.toString() : v.toStringAsFixed(4);

  @override
  Widget build(BuildContext context) {
    final rows = perClass.entries.map((e) {
      final m = e.value;
      return DataRow(cells: [
        DataCell(Text(e.key)),
        DataCell(Text(_fmt(m['precision'] ?? 0))),
        DataCell(Text(_fmt(m['recall'] ?? 0))),
        DataCell(Text(_fmt(m['f1'] ?? 0))),
        DataCell(Text(_fmt(m['TP'] ?? 0))),
        DataCell(Text(_fmt(m['FP'] ?? 0))),
      ]);
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 44,
            columns: const [
              DataColumn(label: Text('Class')),
              DataColumn(label: Text('Precision')),
              DataColumn(label: Text('Recall')),
              DataColumn(label: Text('F1')),
              DataColumn(label: Text('TP')),
              DataColumn(label: Text('FP')),
            ],
            rows: rows,
          ),
        ),
      ),
    );
  }
}

// == HEATMAP MATRICE DI CONFUSIONE ==
class _ConfusionHeatmap extends StatelessWidget {
  final List<String> labels;
  final List<List<int>> matrix;
  const _ConfusionHeatmap({required this.labels, required this.matrix});

  String _short(String s) => s.length <= 10 ? s : '${s.substring(0, 9)}…';

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty || matrix.isEmpty) return _emptyBox();
    final n = matrix.length;
    int maxV = 1;
    for (final r in matrix) {
      for (final v in r) maxV = math.max(maxV, v);
    }
    Color _cellColor(int v) {
      final t = (v / maxV).clamp(0.0, 1.0);
      return Color.lerp(Colors.white, Colors.amber.shade700, t)!;
    }
    const double leftGutter = 90.0;
    const double topGutter = 28.0;
    const double spacing = 6.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.45),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(builder: (context, c) {
          final availW = c.maxWidth;
          final availH = c.maxHeight;
          final gridSize = math.min(
            (availW - leftGutter - 8).clamp(60.0, double.infinity),
            (availH - topGutter - 8).clamp(60.0, double.infinity),
          );

          final cell = ((gridSize - spacing * (n - 1)) / n).clamp(18.0, 56.0);
          final gridPixelW = cell * n + spacing * (n - 1);
          final contentW = leftGutter + gridPixelW; 
          return Align(
            alignment: Alignment.center, 
            child: SizedBox(
              width: contentW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: leftGutter, height: topGutter),
                      SizedBox(
                        width: gridPixelW,
                        height: topGutter,
                        child: Row(
                          children: List.generate(
                            n,
                            (j) => Container(
                              alignment: Alignment.center,
                              width: cell,
                              margin: EdgeInsets.only(right: j == n - 1 ? 0 : spacing),
                              child: Text(_short(labels[j]),
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...List.generate(n, (i) {
                    final row = matrix[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: i == n - 1 ? 0 : spacing),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: leftGutter,
                            child: Text(_short(labels[i]),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                textAlign: TextAlign.left,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          ...List.generate(n, (j) {
                            final v = row[j];
                            final isDiag = i == j;
                            return Container(
                              width: cell,
                              height: cell,
                              margin: EdgeInsets.only(right: j == n - 1 ? 0 : spacing),
                              decoration: BoxDecoration(
                                color: _cellColor(v),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDiag ? Colors.amber.shade800 : Colors.white70,
                                  width: isDiag ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('$v',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDiag ? Colors.black : Colors.black87,
                                      )),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyBox() => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          ),
          alignment: Alignment.center,
          child: const Text('—'),
        ),
      );
}