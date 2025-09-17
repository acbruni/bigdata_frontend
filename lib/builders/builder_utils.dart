// builders/builderutils.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// == Helpers ==
num n_(dynamic v) => (v is num) ? v : num.tryParse('$v') ?? 0;
int i_(dynamic v) => n_(v).toInt();
String s_(dynamic v) => (v == null) ? '' : v.toString();

List<Map<String, dynamic>> ensureListOfMap(dynamic data) {
  if (data is List && data.isNotEmpty && data.first is Map) {
    return data.cast<Map<String, dynamic>>();
  } else if (data is Map) {
    return [data.cast<String, dynamic>()];
  } else if (data is List && data.isEmpty) {
    return <Map<String, dynamic>>[];
  }
  return <Map<String, dynamic>>[];
}

/// == Line chart (fl_chart) ==
class LineChartMini extends StatelessWidget {
  final List<Offset> points;
  final double maxX, maxY;
  final String? title;
  final String Function(double x) xLabelFormatter;
  final String Function(double y) yLabelFormatter;

  const LineChartMini({
    super.key,
    required this.points,
    required this.maxX,
    required this.maxY,
    required this.xLabelFormatter,
    required this.yLabelFormatter,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final spots = (points..sort((a, b) => a.dx.compareTo(b.dx)))
        .map((p) => FlSpot(p.dx, p.dy))
        .toList();

    final safeMaxX = maxX <= 0 ? 1.0 : maxX;
    final safeMaxY = maxY <= 0 ? 1.0 : maxY;
    final xInterval = safeMaxX <= 12 ? 1.0 : (safeMaxX / 12).ceilToDouble();
    final yInterval = (safeMaxY / 5).clamp(1, double.infinity);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
            ),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: safeMaxX,
                minY: 0,
                maxY: safeMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    dotData: const FlDotData(show: true),
                    color: Colors.amber,
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yInterval.toDouble(),
                  verticalInterval: xInterval,
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          xLabelFormatter(value),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: yInterval.toDouble(),
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          yLabelFormatter(value),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black26),
                    bottom: BorderSide(color: Colors.black26),
                    right: BorderSide(color: Colors.transparent),
                    top: BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// == Pie chart (fl_chart) ==
class PieSlice {
  final String label;
  final double value;
  const PieSlice({required this.label, required this.value});
}

class PieChartMini extends StatefulWidget {
  final String title;                
  final List<PieSlice> slices;
  const PieChartMini({super.key, required this.title, required this.slices});

  @override
  State<PieChartMini> createState() => _PieChartMiniState();
}

class _PieChartMiniState extends State<PieChartMini> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final slices = widget.slices;
    final total = slices.fold<double>(
      0, (sum, s) => sum + (s.value.isNaN ? 0 : s.value),
    );

    if (total <= 0) {
      return const Center(child: Text('No data'));
    }

    List<PieChartSectionData> sections() {
      return List.generate(slices.length, (i) {
        final isTouched = i == touchedIndex;
        final radius = isTouched ? 96.0 : 84.0;
        final font   = isTouched ? 22.0 : 14.0;
        final perc   = (slices[i].value * 100 / total);
        return PieChartSectionData(
          value: slices[i].value,
          color: kPalette[i % kPalette.length],
          radius: radius,
          title: '${perc.toStringAsFixed(1)}%',
          titleStyle: TextStyle(
            fontSize: font,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        );
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 2, 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 0,
                          centerSpaceRadius: 80,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, resp) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    resp == null ||
                                    resp.touchedSection == null) {
                                  touchedIndex = -1;
                                } else {
                                  touchedIndex =
                                      resp.touchedSection!.touchedSectionIndex;
                                }
                              });
                            },
                          ),
                          sections: sections(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),
                  SizedBox(
                    width: 200,
                    child: ListView.builder(
                      itemCount: slices.length,
                      itemBuilder: (context, i) {
                        final perc = (slices[i].value * 100 / total);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                color: kPalette[i % kPalette.length],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${slices[i].label} · ${perc.toStringAsFixed(1)}%',
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ],
      ),
    );
  }
}

const List<Color> kPalette = [
  Colors.lightGreenAccent,
  Colors.blue,
];

// == Podium list ====
class PodiumItem {
  final String label;
  final double value;
  final double barRatio;
  final String? subtitle;
  const PodiumItem({
    required this.label,
    required this.value,
    required this.barRatio,
    this.subtitle,
  });
}

class PodiumList extends StatelessWidget {
  final String? title;
  final List<PodiumItem> items;
  const PodiumList({super.key, this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final it = items[i];
                final w = it.barRatio.clamp(0, 1).toDouble();
                return Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${i + 1}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: i < 3 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.black12.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: w,
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? Colors.amber
                                    : (i == 1
                                        ? Colors.grey.shade400
                                        : (i == 2
                                            ? const Color.fromARGB(255, 240, 176, 111)
                                            : Colors.redAccent.withOpacity(0.3 ))),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      it.label,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (it.subtitle != null)
                                    Text(it.subtitle!,
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                  const SizedBox(width: 10),
                                  Text(
                                    it.value.toStringAsFixed(
                                      it.value == it.value.toInt() ? 0 : 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// == Legend swatch ====
class LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;
  const LegendSwatch({super.key, required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 16, height: 16, color: color),
      const SizedBox(width: 6),
      Text(label),
    ]);
  }
}

//  == Simple bar ==
class SimpleBar extends StatelessWidget {
  final double value, max;
  final Color color;
  final String label;
  const SimpleBar(
      {super.key,
      required this.value,
      required this.max,
      required this.color,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= 0 ? 1.0 : max;
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: safeMax,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: value.clamp(0, safeMax),
                color: color,
                width: 60,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          )
        ],
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) => Text(
                label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.black12),
            bottom: BorderSide(color: Colors.black12),
            right: BorderSide(color: Colors.transparent),
            top: BorderSide(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}

