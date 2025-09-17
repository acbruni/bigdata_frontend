// lib/pages/predict_panel.dart
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// == API CONFIG ==
const String API_BASE = 'http://127.0.0.1:8000';
const String EP_PREDICT = '/model/predict';
const String PREDICT_TEXT_KEY = 'text_full';
const Map<String, String> API_HEADERS = {'Content-Type': 'application/json'};

// == PAGE PREDICT INTERFACE ==
class PredictPanelPage extends StatefulWidget {
  const PredictPanelPage({super.key});
  @override
  State<PredictPanelPage> createState() => _PredictPanelPageState();
}
// == STATE PREDICT INTERFACE ==
class _PredictPanelPageState extends State<PredictPanelPage> {
  final _textCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();
  final _mentionsCtrl = TextEditingController();
  final _isRtCtrl = TextEditingController();
  final _verifiedCtrl = TextEditingController();
  final _hourCtrl = TextEditingController();

  bool _isLoading = false;
  bool _hasPrediction = false;
  String _predIdx = '—';
  String _predName = '—';
  List<double>? _probs4;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _hashtagsCtrl.dispose();
    _mentionsCtrl.dispose();
    _isRtCtrl.dispose();
    _verifiedCtrl.dispose();
    _hourCtrl.dispose();
    super.dispose();
  }

  double _parseDoubleOrZero(String s) {
    final v = double.tryParse(s.trim());
    return v ?? 0.0;
  }

  List<String> _parseHashtags(String raw) {
    if (raw.trim().isEmpty) return <String>[];
    return raw
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.replaceAll('#', '').trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      PREDICT_TEXT_KEY: _textCtrl.text,
      'hashtags_arr': _parseHashtags(_hashtagsCtrl.text),
      'mentions_count': _parseDoubleOrZero(_mentionsCtrl.text),
      'is_rt': _parseDoubleOrZero(_isRtCtrl.text),
      'verified': _parseDoubleOrZero(_verifiedCtrl.text),
      'hour_of_day': _parseDoubleOrZero(_hourCtrl.text),
    };
    if (PREDICT_TEXT_KEY != 'text_full') {
      payload['text_full'] = _textCtrl.text;
    }
    return payload;
  }

  Future<void> _doPredict() async {
    setState(() {
      _isLoading = true;
      _hasPrediction = false; 
    });
    final uri = Uri.parse('$API_BASE$EP_PREDICT');
    final body = jsonEncode(_buildPayload());

    try {
      final resp = await http.post(uri, headers: API_HEADERS, body: body);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        final idx = j['predicted_class_index'];
        final name = j['predicted_class_name'];
        final probs = (j['probabilities'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [];
        final padded = List<double>.generate(
          4,
          (i) => i < probs.length ? probs[i] : 0.0,
        );

        setState(() {
          _predIdx = idx?.toString() ?? '—';
          _predName = name?.toString() ?? '—';
          _probs4 = padded;
          _hasPrediction = true;
        });
      } else {
        setState(() {
          _predIdx = 'error ${resp.statusCode}';
          _predName = '—';
          _probs4 = null;
          _hasPrediction = false;
        });
      }
    } catch (e) {
      setState(() {
        _predIdx = 'network error';
        _predName = '—';
        _probs4 = null;
        _hasPrediction = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _doClean() {
    _textCtrl.clear();
    _hashtagsCtrl.clear();
    _mentionsCtrl.text = '';
    _isRtCtrl.text = '';
    _verifiedCtrl.text = '';
    _hourCtrl.text = '';
    setState(() {
      _predIdx = '—';
      _predName = '—';
      _probs4 = null;
      _hasPrediction = false;
    });
  }

  // == WIDGET CARD ==
  Widget glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
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

  OutlineInputBorder _baseGlassBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.9), width: 1),
      );

  Widget glassTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    final baseBorder = _baseGlassBorder();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withOpacity(0.45),
            enabledBorder: baseBorder,
            focusedBorder: baseBorder.copyWith(
              borderSide: BorderSide(
                color: Colors.black.withOpacity(0.75),
                width: 1.2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
  Widget glassInfoBox({
    required String label,
    required String value,
    TextStyle? valueStyle,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          width: double.infinity,
          padding: contentPadding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          ),
          child: Text(
            value,
            style: valueStyle ??
                const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ],
    );
  }
  Widget _gradientButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withOpacity(0.95),
        Colors.black.withOpacity(0.80),
      ],
    );
    return Opacity(
      opacity: onTap == null ? 0.6 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leftForm() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 16),
          child: Text(
            'Fill the gap',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: glassCard(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  glassTextField(
                    label: 'Text *',
                    controller: _textCtrl,
                    hint: 'Write the text / Example: Help! Need water and food.',
                    maxLines: 2,
                    keyboardType: TextInputType.multiline,
                    icon: Icons.edit_outlined,
                  ),
                  const SizedBox(height: 14),
                  glassTextField(
                    label: 'Hashtags',
                    controller: _hashtagsCtrl,
                    hint: 'help, flood, rescue',
                    maxLines: 2,
                    keyboardType: TextInputType.multiline,
                    icon: Icons.tag_outlined,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: glassTextField(
                          label: 'Mentions count',
                          controller: _mentionsCtrl,
                          hint: 'Example: 15',
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          icon: Icons.alternate_email_outlined,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: glassTextField(
                          label: 'Retweeted',
                          controller: _isRtCtrl,
                          hint: 'Choose between 0 and 1',
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          icon: Icons.repeat_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: glassTextField(
                          label: 'Verified',
                          controller: _verifiedCtrl,
                          hint: 'Choose between 0 and 1',
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          icon: Icons.verified_user_outlined,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: glassTextField(
                          label: 'Hour of day',
                          controller: _hourCtrl,
                          hint: 'Example: 23',
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          icon: Icons.schedule_outlined,
                        ),
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
            _gradientButton(
              icon: Icons.cleaning_services_outlined,
              label: 'Clean',
              onTap: _isLoading ? null : _doClean,
            ),
            const Spacer(),
            _gradientButton(
              icon: Icons.auto_graph,
              label: 'Predict',
              onTap: _isLoading ? null : _doPredict,
            ),
          ],
        ),
      ],
    );
  }

  // == WIDGET BLOCCO PROBABILITÀ ==
  Widget _probBlock(String title, double? value) {
    final shown = _hasPrediction && value != null;
    final text = shown ? value.toStringAsFixed(4) : '—';
    return glassInfoBox(
      label: title,
      value: text,
      valueStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _rightResults() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 16),
          child: Text(
            'Results',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: glassCard(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  glassInfoBox(
                    label: 'Predicted class index',
                    value: _hasPrediction ? _predIdx : '—',
                  ),
                  const SizedBox(height: 14),
                  glassInfoBox(
                    label: 'Predicted class name',
                    value: _hasPrediction ? _predName : '—',
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 6),
                      child: Text(
                        'Probabilities\n',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _probBlock(
                          'Request/Need',
                          _probs4 != null ? _probs4![0] : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _probBlock(
                          'Offer/Donation',
                          _probs4 != null ? _probs4![1] : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _probBlock(
                          'Damage/Impact',
                          _probs4 != null ? _probs4![2] : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _probBlock(
                          'Other',
                          _probs4 != null ? _probs4![3] : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Opacity(
                    opacity: 0.6,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _hasPrediction
                            ? '\nThe values show the last executed prediction.'
                            : '\nExecutes the prediction to see results' ,                       
                            style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
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

// == PAGE BUILD ==
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _leftForm(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _rightResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}