import 'dart:math';
import 'package:flutter/material.dart';

class SkeetBackground {
  final String name;
  final List<Color> skyColors;
  final List<double>? skyStops;
  final Color groundTop;
  final Color groundBottom;
  final Widget Function(double w, double h)? decorator;

  const SkeetBackground({
    required this.name,
    required this.skyColors,
    this.skyStops,
    required this.groundTop,
    required this.groundBottom,
    this.decorator,
  });
}

class SkeetBackgroundWidget extends StatelessWidget {
  final SkeetBackground bg;
  const SkeetBackgroundWidget({super.key, required this.bg});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bg.skyColors,
                stops: bg.skyStops,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bg.groundTop, bg.groundBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        if (bg.decorator != null) bg.decorator!(w, h),
      ],
    );
  }
}

// ── Decorator helpers ─────────────────────────────────────────────────────────

Widget _circle(double w, double h, Color c, double xFrac, double yFrac, double r) =>
    Positioned(
      left: w * xFrac - r,
      top: h * yFrac - r,
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: r * 0.8)],
        ),
      ),
    );

Widget _starField(double w, double h, int count, Color c, int seed) {
  final rng = Random(seed);
  return Stack(
    children: List.generate(count, (i) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * 0.65;
      final r = 0.8 + rng.nextDouble() * 2.0;
      return Positioned(
        left: x, top: y,
        child: Container(
          width: r, height: r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
      );
    }),
  );
}

Widget _buildingRow(double w, double h, List<List<double>> defs, Color light, Color dark) =>
    Positioned(
      bottom: 56, left: 0, right: 0,
      child: SizedBox(
        height: h * 0.28,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: defs.map((d) => Container(
            width: w * d[0],
            height: h * d[1],
            color: d[2] == 0 ? dark : light,
          )).toList(),
        ),
      ),
    );

Widget _treeRow(double w, double h, Color trunk, Color canopy) =>
    Positioned(
      bottom: 56, left: 0, right: 0,
      child: SizedBox(
        height: h * 0.35,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (i) => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 18.0 + (i % 3) * 8,
                height: (h * 0.35 - 8) * (0.6 + (i % 3) * 0.2),
                color: canopy,
              ),
              Container(width: 6, height: 8, color: trunk),
            ],
          )),
        ),
      ),
    );

// ── Mountain painter ──────────────────────────────────────────────────────────

class _MountainPainter extends CustomPainter {
  final List<Color> colors;
  const _MountainPainter({required this.colors});

  static const _peaks = [
    [0.0, 0.5, 0.22, 1],
    [0.12, 0.62, 0.35, 0],
    [0.28, 0.78, 0.52, 1],
    [0.48, 0.88, 0.65, 0],
    [0.60, 1.05, 0.80, 1],
    [0.78, 1.05, 0.88, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in _peaks) {
      final paint = Paint()..color = colors[m[3].toInt()];
      final path = Path()
        ..moveTo(m[0] * size.width, size.height)
        ..lineTo(m[2] * size.width, 0)
        ..lineTo(m[1] * size.width, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

Widget _mountains(double w, double h, List<Color> colors) =>
    Positioned(
      bottom: 56, left: 0, right: 0,
      child: SizedBox(
        height: h * 0.32,
        child: CustomPaint(
          painter: _MountainPainter(colors: colors),
          size: Size(w, h * 0.32),
        ),
      ),
    );

// ── Rain painter ──────────────────────────────────────────────────────────────

class _RainPainter extends CustomPainter {
  final int seed;
  const _RainPainter({this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;
    final rng = Random(seed);
    for (int i = 0; i < 70; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 9, y + 20), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Aurora painter ────────────────────────────────────────────────────────────

class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bands = [
      (0.20, const Color(0x5500FF7F)),
      (0.32, const Color(0x447B68EE)),
      (0.44, const Color(0x3300FFFF)),
    ];
    for (final (yFrac, col) in bands) {
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, col, Colors.transparent],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill;
      final baseY = size.height * yFrac;
      final path = Path()..moveTo(0, baseY + 10);
      for (double x = 0; x <= size.width; x += 15) {
        path.lineTo(x, baseY + 18 * sin(x / 60));
      }
      path.lineTo(size.width, size.height * 0.65);
      path.lineTo(0, size.height * 0.65);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Heat wave painter ─────────────────────────────────────────────────────────

class _HeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.38 + i * 0.09);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 8) {
        path.lineTo(x, y + 5 * sin(x / 25 + i));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Lightning painter ─────────────────────────────────────────────────────────

class _LightningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2.5;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w * 0.78, h * 0.05), Offset(w * 0.72, h * 0.26), paint);
    canvas.drawLine(Offset(w * 0.72, h * 0.26), Offset(w * 0.76, h * 0.29), paint);
    canvas.drawLine(Offset(w * 0.76, h * 0.29), Offset(w * 0.69, h * 0.46), paint);
    // second bolt left
    canvas.drawLine(Offset(w * 0.22, h * 0.08), Offset(w * 0.18, h * 0.22), paint);
    canvas.drawLine(Offset(w * 0.18, h * 0.22), Offset(w * 0.22, h * 0.25), paint);
    canvas.drawLine(Offset(w * 0.22, h * 0.25), Offset(w * 0.16, h * 0.40), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 20 Background definitions ─────────────────────────────────────────────────

final List<SkeetBackground> kSkeetBackgrounds = [
  // 0: Levels 1-5 — Morning Bangkok
  SkeetBackground(
    name: 'Morning Bangkok',
    skyColors: [const Color(0xFF87CEEB), const Color(0xFFB0E2FF), const Color(0xFFFFD700), const Color(0xFFFFA500)],
    skyStops: [0.0, 0.4, 0.72, 1.0],
    groundTop: const Color(0xFF228B22),
    groundBottom: const Color(0xFF1a6b1a),
    decorator: (w, h) => _circle(w, h, const Color(0xFFFFE033), 0.88, 0.11, 16),
  ),

  // 1: Levels 6-10 — Midday Heat
  SkeetBackground(
    name: 'Midday Heat',
    skyColors: [const Color(0xFF1E90FF), const Color(0xFF4169E1), const Color(0xFFDDEEFF)],
    skyStops: [0.0, 0.55, 1.0],
    groundTop: const Color(0xFFDAA520),
    groundBottom: const Color(0xFFB8860B),
    decorator: (w, h) => _circle(w, h, Colors.white.withValues(alpha: 0.92), 0.5, 0.07, 24),
  ),

  // 2: Levels 11-15 — Bangkok Streets
  SkeetBackground(
    name: 'Bangkok Streets',
    skyColors: [const Color(0xFF2F4F8F), const Color(0xFF1a3a6b), const Color(0xFF708090)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFF404040),
    groundBottom: const Color(0xFF303030),
    decorator: (w, h) => _buildingRow(w, h, [
      [0.09, 0.12, 0], [0.07, 0.08, 1], [0.11, 0.20, 0],
      [0.08, 0.10, 1], [0.13, 0.22, 0], [0.07, 0.14, 1],
      [0.10, 0.16, 0], [0.12, 0.11, 1], [0.09, 0.18, 0],
      [0.14, 0.09, 1],
    ], const Color(0xFF2a2a4a), const Color(0xFF1a1a3a)),
  ),

  // 3: Levels 16-20 — Afternoon Storm
  SkeetBackground(
    name: 'Afternoon Storm',
    skyColors: [const Color(0xFF2F2F4F), const Color(0xFF1C1C3A), const Color(0xFF4A4A6A)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFF1a3a1a),
    groundBottom: const Color(0xFF0d200d),
    decorator: (w, h) => const Positioned.fill(
      child: CustomPaint(painter: _RainPainter(seed: 33)),
    ),
  ),

  // 4: Levels 21-25 — Sunset Orange
  SkeetBackground(
    name: 'Sunset Orange',
    skyColors: [const Color(0xFFCC2200), const Color(0xFFFF4500), const Color(0xFFFFD700), const Color(0xFFFF8C00)],
    skyStops: [0.0, 0.3, 0.65, 1.0],
    groundTop: const Color(0xFF8B4513),
    groundBottom: const Color(0xFF6B3410),
    decorator: (w, h) => _circle(w, h, const Color(0xFFFF8000).withValues(alpha: 0.85), 0.5, 0.70, 32),
  ),

  // 5: Levels 26-30 — Purple Dusk
  SkeetBackground(
    name: 'Purple Dusk',
    skyColors: [const Color(0xFF4B0082), const Color(0xFF800080), const Color(0xFFFF69B4)],
    skyStops: [0.0, 0.55, 1.0],
    groundTop: const Color(0xFF2F0F2F),
    groundBottom: const Color(0xFF1a081a),
    decorator: (w, h) => _starField(w, h, 28, Colors.white.withValues(alpha: 0.65), 42),
  ),

  // 6: Levels 31-35 — City Night
  SkeetBackground(
    name: 'City Night',
    skyColors: [const Color(0xFF000033), const Color(0xFF000066), const Color(0xFF1a1a4a)],
    skyStops: [0.0, 0.6, 1.0],
    groundTop: const Color(0xFF0d0d0d),
    groundBottom: const Color(0xFF1a1a1a),
    decorator: (w, h) => Stack(children: [
      _starField(w, h, 45, Colors.white.withValues(alpha: 0.55), 99),
      _buildingRow(w, h, [
        [0.08, 0.15, 0], [0.06, 0.10, 1], [0.10, 0.22, 0],
        [0.07, 0.12, 1], [0.12, 0.24, 0], [0.09, 0.16, 1],
        [0.08, 0.13, 0], [0.11, 0.19, 1], [0.10, 0.11, 0],
        [0.09, 0.17, 1], [0.10, 0.20, 0],
      ], const Color(0xFF0a0a20), const Color(0xFF05050f)),
    ]),
  ),

  // 7: Levels 36-40 — Neon Bangkok
  SkeetBackground(
    name: 'Neon Bangkok',
    skyColors: [const Color(0xFF0d0d2b), const Color(0xFF1a0033), const Color(0xFF220055)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFF1a001a),
    groundBottom: const Color(0xFF0d000d),
    decorator: (w, h) => Stack(children: [
      _starField(w, h, 20, Colors.white.withValues(alpha: 0.3), 7),
      for (final data in [
        [0.10, const Color(0xCCFF00FF)],
        [0.28, const Color(0xCC00FFFF)],
        [0.50, const Color(0xCCFF00FF)],
        [0.68, const Color(0xCC00FFFF)],
        [0.88, const Color(0xCCFF00FF)],
      ]) Positioned(
        left: w * (data[0] as double), top: h * 0.45, bottom: 56,
        child: Container(
          width: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, data[1] as Color],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    ]),
  ),

  // 8: Levels 41-45 — Rainy Season
  SkeetBackground(
    name: 'Rainy Season',
    skyColors: [const Color(0xFF2F4F4F), const Color(0xFF1C3333), const Color(0xFF556B6B)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFF1a3a3a),
    groundBottom: const Color(0xFF0d2020),
    decorator: (w, h) => const Positioned.fill(
      child: CustomPaint(painter: _RainPainter(seed: 88)),
    ),
  ),

  // 9: Levels 46-50 — Temple Grounds
  SkeetBackground(
    name: 'Temple Grounds',
    skyColors: [const Color(0xFF4169E1), const Color(0xFF1E90FF), const Color(0xFFDAA520)],
    skyStops: [0.0, 0.60, 1.0],
    groundTop: const Color(0xFF8B7355),
    groundBottom: const Color(0xFF6B5335),
    decorator: (w, h) => _mountains(w, h, [const Color(0xFF4a3520), const Color(0xFF5a4530)]),
  ),

  // 10: Levels 51-55 — Mountain View
  SkeetBackground(
    name: 'Mountain View',
    skyColors: [const Color(0xFF87CEEB), const Color(0xFF6495ED), const Color(0xFF8DB0D0)],
    skyStops: [0.0, 0.6, 1.0],
    groundTop: const Color(0xFF228B22),
    groundBottom: const Color(0xFF1a6b1a),
    decorator: (w, h) => _mountains(w, h, [const Color(0xFF5a7a5a), const Color(0xFF3a5a3a)]),
  ),

  // 11: Levels 56-60 — Beach Thailand
  SkeetBackground(
    name: 'Beach Thailand',
    skyColors: [const Color(0xFF00CED1), const Color(0xFF20B2AA), const Color(0xFF40E0D0)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFFF0E68C),
    groundBottom: const Color(0xFFDAA520),
    decorator: (w, h) => Stack(children: [
      _circle(w, h, const Color(0xFFFFFF00), 0.85, 0.10, 22),
      Positioned(
        bottom: 56, left: 0, right: 0,
        child: Container(
          height: 14,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x9940E0D0), Color(0x4440E0D0), Color(0x9940E0D0)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    ]),
  ),

  // 12: Levels 61-65 — Forest Path
  SkeetBackground(
    name: 'Forest Path',
    skyColors: [const Color(0xFF228B22), const Color(0xFF006400), const Color(0xFF003300)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFF8B4513),
    groundBottom: const Color(0xFF6B3410),
    decorator: (w, h) => _treeRow(w, h, const Color(0xFF4a2000), const Color(0xFF003300)),
  ),

  // 13: Levels 66-70 — Desert Heat
  SkeetBackground(
    name: 'Desert Heat',
    skyColors: [const Color(0xFFFF8C00), const Color(0xFFFF4500), const Color(0xFFDAA520)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFFDEB887),
    groundBottom: const Color(0xFFD2691E),
    decorator: (w, h) => Positioned.fill(
      child: CustomPaint(painter: _HeatPainter()),
    ),
  ),

  // 14: Levels 71-75 — Snowy Mountain
  SkeetBackground(
    name: 'Snowy Mountain',
    skyColors: [const Color(0xFFB0C4DE), const Color(0xFF778899), const Color(0xFFCCCCDD)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFFE8E8F0),
    groundBottom: const Color(0xFFD0D0E0),
    decorator: (w, h) => _mountains(w, h, [Colors.white, const Color(0xFFE0E0F0)]),
  ),

  // 15: Levels 76-80 — Space Station
  SkeetBackground(
    name: 'Space Station',
    skyColors: [const Color(0xFF000000), const Color(0xFF0d0d1a), const Color(0xFF000033)],
    skyStops: [0.0, 0.6, 1.0],
    groundTop: const Color(0xFF1C1C1C),
    groundBottom: const Color(0xFF0d0d0d),
    decorator: (w, h) => _starField(w, h, 90, Colors.white.withValues(alpha: 0.75), 77),
  ),

  // 16: Levels 81-85 — Aurora
  SkeetBackground(
    name: 'Aurora',
    skyColors: [const Color(0xFF000033), const Color(0xFF0d0033), const Color(0xFF003322)],
    skyStops: [0.0, 0.45, 1.0],
    groundTop: const Color(0xFF0d1a0d),
    groundBottom: const Color(0xFF080d08),
    decorator: (w, h) => Stack(children: [
      _starField(w, h, 55, Colors.white.withValues(alpha: 0.55), 16),
      Positioned.fill(child: CustomPaint(painter: _AuroraPainter())),
    ]),
  ),

  // 17: Levels 86-90 — Volcanic
  SkeetBackground(
    name: 'Volcanic',
    skyColors: [const Color(0xFF1C0000), const Color(0xFF3D0000), const Color(0xFFDD3300)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFF1C0000),
    groundBottom: const Color(0xFF0d0000),
    decorator: (w, h) => Stack(children: [
      Positioned(
        bottom: 56, left: 0, right: 0,
        child: Container(
          height: 22,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFCC2200), Color(0xFFFF6600), Color(0xFFCC2200)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 56, left: 0, right: 0,
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0x55FF4400)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    ]),
  ),

  // 18: Levels 91-95 — Lightning Storm
  SkeetBackground(
    name: 'Lightning Storm',
    skyColors: [const Color(0xFF1C1C2E), const Color(0xFF0d0d1a), const Color(0xFF2E2E4A)],
    skyStops: [0.0, 0.5, 1.0],
    groundTop: const Color(0xFF0d0d0d),
    groundBottom: const Color(0xFF1a1a1a),
    decorator: (w, h) => Positioned.fill(
      child: CustomPaint(painter: _LightningPainter()),
    ),
  ),

  // 19: Levels 96-100 — Golden Temple (final)
  SkeetBackground(
    name: 'Golden Temple',
    skyColors: [const Color(0xFFD4A017), const Color(0xFFB8860B), const Color(0xFFFFD700), const Color(0xFFFFA500)],
    skyStops: [0.0, 0.3, 0.7, 1.0],
    groundTop: const Color(0xFFB8860B),
    groundBottom: const Color(0xFF8B6914),
    decorator: (w, h) => Stack(children: [
      _mountains(w, h, [const Color(0xFFB8860B), const Color(0xFF8B6914)]),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              width: 8,
            ),
          ),
        ),
      ),
    ]),
  ),
];
