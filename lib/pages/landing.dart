import 'package:bigdata_natural_disaster/pages/api_query.dart';
import 'package:bigdata_natural_disaster/pages/model.dart';
import 'package:flutter/material.dart';

/// Home con AppBar in stile Apple + 2 card interattive
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variabili di stato per animazioni
  bool _appear = false;      // controlla l’entrata delle card
  bool _hoverLeft = false;   // true se il mouse è sopra la card sinistra
  bool _hoverRight = false;  // true se il mouse è sopra la card destra

  @override
  void initState() {
    super.initState();
    // Dopo il primo frame → attivo l’animazione di entrata delle card
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _appear = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Uso CustomScrollView per avere SliverAppBar che può collassare
      body: CustomScrollView(
        slivers: [
          // ─────────────────────────────
          // HEADER 
          // ─────────────────────────────
          SliverAppBar(
            pinned: true,                 // resta visibile in alto quando scrolli
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            expandedHeight: 700,          // altezza quando è espansa
            centerTitle: true,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                const maxExtent = 220.0;
                final h = constraints.maxHeight;

                // progress = 1.0 quando è tutta espansa, 0.0 quando collassata
                final progress = ((h - kToolbarHeight) /
                        (maxExtent - kToolbarHeight))
                    .clamp(0.0, 1.0);

                // Calcolo trasformazioni:
                final double translateY = -20 * (1 - progress); // si sposta su
                final double opacity = progress;                // fade out

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, translateY),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Titolo grande
                              Text('Natural Disaster in Tweets:\n \ \ \ \ \ \ \ \ Big Data Analysis',
                                  style: Theme.of(context).textTheme.displayLarge),
                              const SizedBox(height: 8),
                              // Sottotitolo
                              Text(
                                'by Anna Chiara Bruni & Demetrio Romeo',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // linea sottile in basso (solo estetica)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 1,
                        color: Colors.black.withOpacity(0.06),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Spazio vuoto tra header e card
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ─────────────────────────────
          // LE DUE CARD
          // ─────────────────────────────
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final isNarrow = w < 820; // su schermi stretti → impila

                // Card sinistra
                Widget left = _HoverCard(
                  title: 'Query',
                  color: Colors.black,
                  appear: _appear,
                  hovered: _hoverLeft,
                  onHoverChanged: (v) => setState(() => _hoverLeft = v),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApiQueryPage())),
                );

                // Card destra
                Widget right = _HoverCard(
                  title: 'Model',
                  color: Colors.black,
                  appear: _appear,
                  hovered: _hoverRight,
                  onHoverChanged: (v) => setState(() => _hoverRight = v),
                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModelPage())),
                );

                // Se lo schermo è stretto → colonna, altrimenti Row
                if (isNarrow) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        left,
                        const SizedBox(height: 20),
                        right,
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: left),
                        const SizedBox(width: 24),
                        Flexible(child: right),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

/// ─────────────────────────────
/// WIDGET CARD INTERATTIVA
/// ─────────────────────────────
class _HoverCard extends StatelessWidget {
  final String title;                // titolo della card
  final Color color;                 // colore di sfondo
  final bool appear;                 // true se deve animarsi in entrata
  final bool hovered;                // true se mouse sopra
  final void Function(bool) onHoverChanged;
  final VoidCallback onTap;

  const _HoverCard({
    required this.title,
    required this.color,
    required this.appear,
    required this.hovered,
    required this.onHoverChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double baseScale = appear ? 1.0 : 0.9;
    final double scale = hovered ? baseScale * 1.05 : baseScale;

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: appear ? 1 : 0,
          curve: Curves.easeOut,
          child: GestureDetector(
            onTap: onTap, // click → naviga
            child: Container(
              height: 260,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.95),
                    color.withOpacity(0.80),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}