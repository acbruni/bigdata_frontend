import 'package:bigdata_natural_disaster/pages/latest_metrics.dart';
import 'package:bigdata_natural_disaster/pages/predict_panel.dart';
import 'package:bigdata_natural_disaster/pages/train_panel.dart';
import 'package:flutter/material.dart';

// == PAGE MODEL INTERFACE ==
class ModelPage extends StatefulWidget {
  const ModelPage({super.key});
  @override
  State<ModelPage> createState() => _ModelPageState();
}
// == STATE MODEL INTERFACE ==
class _ModelPageState extends State<ModelPage> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withOpacity(0.95),
        Colors.black.withOpacity(0.80),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        title: const Text(
          'Model Interface',
          style: TextStyle(color: Colors.white, fontFamily: 'San Francisco'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AppBarIconTab(
                  icon: Icons.insights_outlined,
                  label: 'Metrics',
                  selected: _selected == 0,
                  onTap: () => setState(() => _selected = 0),
                ),
                const SizedBox(width: 28),
                const SizedBox(height: 70, child: VerticalDivider(color: Colors.white38)),
                const SizedBox(width: 28),
                _AppBarIconTab(
                  icon: Icons.play_circle_outlined,
                  label: 'Train',
                  selected: _selected == 1,
                  onTap: () => setState(() => _selected = 1),
                ),
                const SizedBox(width: 28),
                const SizedBox(height: 70, child: VerticalDivider(color: Colors.white38)),
                const SizedBox(width: 28),
                _AppBarIconTab(
                  icon: Icons.lightbulb_outlined,
                  label: 'Predict',
                  selected: _selected == 2,
                  onTap: () => setState(() => _selected = 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: () {
          switch (_selected) {
            case 1:
              return const TrainPanelPage(key: ValueKey('train'));
            case 2:
              return const PredictPanelPage(key: ValueKey('predict'));
            case 0:
            default:
              return const LatestMetricsPage(key: ValueKey('metrics'));
          }
        }(),
      ),
    );
  }
}
// == WIDGET CARD INTERATTIVA ==
class _AppBarIconTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AppBarIconTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseOpacity = selected ? 1.0 : 0.65;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: Colors.white.withOpacity(baseOpacity)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(baseOpacity),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}