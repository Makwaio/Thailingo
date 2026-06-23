import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThaiMascot extends StatelessWidget {
  final double size;
  final MascotMood mood;
  final String? speechText;

  const ThaiMascot({
    super.key,
    this.size = 80,
    this.mood = MascotMood.happy,
    this.speechText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (speechText != null) ...[
          _SpeechBubble(text: speechText!),
          const SizedBox(height: 6),
        ],
        CustomPaint(
          size: Size(size, size * 1.2),
          painter: _MascotPainter(mood: mood),
        ),
      ],
    );
  }
}

enum MascotMood { happy, excited, sad, encouraging, neutral }

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  const _MascotPainter({required this.mood});

  static const _skin = Color(0xFFD4956A);
  static const _skinShade = Color(0xFFBF7D52);
  static const _mongkolRed = Color(0xFFB5001C);
  static const _mongkolGold = Color(0xFFD4A017);
  static const _dark = Color(0xFF1A0A00);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawShorts(canvas, w, h);
    _drawTorso(canvas, w, h);
    _drawArms(canvas, w, h);
    _drawNeck(canvas, w, h);
    _drawHead(canvas, w, h);
    _drawHair(canvas, w, h);
    _drawMongkol(canvas, w, h);
    _drawFace(canvas, w, h);
    _drawFists(canvas, w, h);
  }

  void _drawShorts(Canvas canvas, double w, double h) {
    // Legs (skin) below shorts
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.29, h * 0.84, w * 0.16, h * 0.15),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = _skin,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.55, h * 0.84, w * 0.16, h * 0.15),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = _skin,
    );
    // Red Muay Thai shorts
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.65, w * 0.56, h * 0.22),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = _mongkolRed,
    );
    // Gold waistband
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.63, w * 0.60, h * 0.06),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = _mongkolGold,
    );
    // Gold center stripe on shorts
    canvas.drawRect(
      Rect.fromLTWH(w * 0.46, h * 0.67, w * 0.08, h * 0.20),
      Paint()..color = _mongkolGold.withValues(alpha: 0.5),
    );
  }

  void _drawTorso(Canvas canvas, double w, double h) {
    // Athletic trapezoid torso — wider at shoulders
    final path = Path()
      ..moveTo(w * 0.16, h * 0.44)
      ..lineTo(w * 0.22, h * 0.65)
      ..lineTo(w * 0.78, h * 0.65)
      ..lineTo(w * 0.84, h * 0.44)
      ..quadraticBezierTo(w * 0.50, h * 0.40, w * 0.16, h * 0.44)
      ..close();
    canvas.drawPath(path, Paint()..color = _skin);
    // Center muscle line
    canvas.drawLine(
      Offset(w * 0.50, h * 0.44),
      Offset(w * 0.50, h * 0.64),
      Paint()
        ..color = _skinShade
        ..strokeWidth = 1.0,
    );
  }

  void _drawArms(Canvas canvas, double w, double h) {
    final armPaint = Paint()
      ..color = _skin
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round;

    if (mood == MascotMood.sad) {
      canvas.drawLine(Offset(w * 0.16, h * 0.48), Offset(w * 0.05, h * 0.70), armPaint);
      canvas.drawLine(Offset(w * 0.84, h * 0.48), Offset(w * 0.95, h * 0.70), armPaint);
    } else if (mood == MascotMood.excited) {
      // Victory — both arms raised high
      canvas.drawLine(Offset(w * 0.16, h * 0.48), Offset(w * 0.05, h * 0.25), armPaint);
      canvas.drawLine(Offset(w * 0.84, h * 0.48), Offset(w * 0.95, h * 0.25), armPaint);
    } else {
      // Muay Thai guard — upper arm down, forearm back up
      canvas.drawLine(Offset(w * 0.16, h * 0.48), Offset(w * 0.08, h * 0.62), armPaint);
      canvas.drawLine(Offset(w * 0.08, h * 0.62), Offset(w * 0.18, h * 0.36), armPaint);
      canvas.drawLine(Offset(w * 0.84, h * 0.48), Offset(w * 0.92, h * 0.62), armPaint);
      canvas.drawLine(Offset(w * 0.92, h * 0.62), Offset(w * 0.82, h * 0.36), armPaint);
    }
  }

  void _drawFists(Canvas canvas, double w, double h) {
    if (mood == MascotMood.sad) {
      _drawFist(canvas, Offset(w * 0.05, h * 0.70), w * 0.08);
      _drawFist(canvas, Offset(w * 0.95, h * 0.70), w * 0.08);
    } else if (mood == MascotMood.excited) {
      _drawFist(canvas, Offset(w * 0.05, h * 0.19), w * 0.08);
      _drawFist(canvas, Offset(w * 0.95, h * 0.19), w * 0.08);
    } else {
      _drawFist(canvas, Offset(w * 0.18, h * 0.30), w * 0.08);
      _drawFist(canvas, Offset(w * 0.82, h * 0.30), w * 0.08);
    }
  }

  void _drawFist(Canvas canvas, Offset center, double r) {
    // White hand wrap
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 2.2, height: r * 1.6),
      Paint()..color = Colors.white,
    );
    // Red stripe across wrap
    canvas.drawRect(
      Rect.fromCenter(center: center, width: r * 2.2, height: r * 0.5),
      Paint()..color = _mongkolRed,
    );
    // Outline
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 2.2, height: r * 1.6),
      Paint()
        ..color = _dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawNeck(Canvas canvas, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.37, w * 0.24, h * 0.09),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = _skin,
    );
  }

  void _drawHead(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromLTWH(w * 0.17, h * 0.05, w * 0.66, h * 0.36),
      Paint()..color = _skin,
    );
  }

  void _drawHair(Canvas canvas, double w, double h) {
    // Short dark hair — top portion of head
    canvas.drawPath(
      Path()..addOval(Rect.fromLTWH(w * 0.17, h * 0.03, w * 0.66, h * 0.20)),
      Paint()..color = _dark,
    );
  }

  void _drawMongkol(Canvas canvas, double w, double h) {
    // Red headband across forehead
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.155, w * 0.70, h * 0.072),
        Radius.circular(w * 0.025),
      ),
      Paint()..color = _mongkolRed,
    );
    // Gold border on headband
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.155, w * 0.70, h * 0.072),
        Radius.circular(w * 0.025),
      ),
      Paint()
        ..color = _mongkolGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Gold center jewel
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.191),
      w * 0.045,
      Paint()..color = _mongkolGold,
    );
  }

  void _drawFace(Canvas canvas, double w, double h) {
    // Angled brows — focused fighter expression
    final browPaint = Paint()
      ..color = _dark
      ..strokeWidth = w * 0.038
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.28, h * 0.255), Offset(w * 0.40, h * 0.272), browPaint);
    canvas.drawLine(Offset(w * 0.60, h * 0.272), Offset(w * 0.72, h * 0.255), browPaint);

    // Eyes
    _drawEye(canvas, Offset(w * 0.35, h * 0.305), w * 0.06);
    _drawEye(canvas, Offset(w * 0.65, h * 0.305), w * 0.06);

    // Mouth
    _drawMouth(canvas, Offset(w * 0.50, h * 0.370), w * 0.13);
  }

  void _drawEye(Canvas canvas, Offset center, double r) {
    if (mood == MascotMood.sad) {
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - r, center.dy)
          ..quadraticBezierTo(center.dx, center.dy + r * 0.9, center.dx + r, center.dy),
        Paint()
          ..color = _dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      return;
    }
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 2.0, height: r * 1.3),
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + (mood == MascotMood.excited ? -r * 0.1 : 0)),
        width: r * 0.95,
        height: r * 1.0,
      ),
      Paint()..color = _dark,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + r * 0.25, center.dy - r * 0.25),
        width: r * 0.28,
        height: r * 0.28,
      ),
      Paint()..color = Colors.white,
    );
  }

  void _drawMouth(Canvas canvas, Offset center, double width) {
    final paint = Paint()
      ..color = _dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final path = Path();
    switch (mood) {
      case MascotMood.happy || MascotMood.encouraging:
        path.moveTo(center.dx - width * 0.4, center.dy);
        path.quadraticBezierTo(center.dx, center.dy + width * 0.32, center.dx + width * 0.4, center.dy);
      case MascotMood.excited:
        path.moveTo(center.dx - width * 0.5, center.dy);
        path.quadraticBezierTo(center.dx, center.dy + width * 0.50, center.dx + width * 0.5, center.dy);
      case MascotMood.sad:
        path.moveTo(center.dx - width * 0.4, center.dy + width * 0.18);
        path.quadraticBezierTo(center.dx, center.dy - width * 0.22, center.dx + width * 0.4, center.dy + width * 0.18);
      default:
        // Neutral — determined straight line
        path.moveTo(center.dx - width * 0.28, center.dy);
        path.lineTo(center.dx + width * 0.28, center.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MascotPainter old) => old.mood != mood;
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.thaiGold, width: 2),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BobbingMascot extends StatefulWidget {
  final double size;
  final MascotMood mood;
  final String? speechText;

  const BobbingMascot({
    super.key,
    this.size = 80,
    this.mood = MascotMood.happy,
    this.speechText,
  });

  @override
  State<BobbingMascot> createState() => _BobbingMascotState();
}

class _BobbingMascotState extends State<BobbingMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, (_ctrl.value - 0.5) * 10),
        child: child,
      ),
      child: ThaiMascot(
        size: widget.size,
        mood: widget.mood,
        speechText: widget.speechText,
      ),
    );
  }
}
