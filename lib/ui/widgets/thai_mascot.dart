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

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body (Thai outfit — red/gold)
    final bodyPaint = Paint()..color = AppTheme.thaiRed;
    final goldPaint = Paint()..color = AppTheme.thaiGold;
    final skinPaint = Paint()..color = const Color(0xFFD4956A);
    final darkPaint = Paint()..color = const Color(0xFF1A0A00);
    final outlinePaint = Paint()
      ..color = const Color(0xFF1A0A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.48, w * 0.6, h * 0.38),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Gold sash across body
    final sashPath = Path()
      ..moveTo(w * 0.2, h * 0.58)
      ..lineTo(w * 0.8, h * 0.58)
      ..lineTo(w * 0.8, h * 0.65)
      ..lineTo(w * 0.2, h * 0.65)
      ..close();
    canvas.drawPath(sashPath, goldPaint);

    // Neck
    canvas.drawRect(
        Rect.fromLTWH(w * 0.38, h * 0.42, w * 0.24, h * 0.08), skinPaint);

    // Head
    final headPaint = Paint()..color = const Color(0xFFD4956A);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.15, h * 0.08, w * 0.7, h * 0.38), headPaint);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.15, h * 0.08, w * 0.7, h * 0.38), outlinePaint);

    // Hair (black)
    final hairPath = Path()
      ..addOval(Rect.fromLTWH(w * 0.15, h * 0.04, w * 0.7, h * 0.22));
    canvas.drawPath(hairPath, darkPaint);

    // Traditional headdress (gold)
    final crownPath = Path()
      ..moveTo(w * 0.35, h * 0.08)
      ..lineTo(w * 0.5, h * -0.02)
      ..lineTo(w * 0.65, h * 0.08);
    final crownPaint = Paint()
      ..color = AppTheme.thaiGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(crownPath, crownPaint);
    canvas.drawCircle(Offset(w * 0.5, h * -0.02), w * 0.045, goldPaint);

    // Eyes
    final eyeY = h * 0.24;
    _drawEye(canvas, Offset(w * 0.36, eyeY), w * 0.065, mood);
    _drawEye(canvas, Offset(w * 0.64, eyeY), w * 0.065, mood);

    // Mouth
    _drawMouth(canvas, Offset(w * 0.5, h * 0.34), w * 0.14, mood);

    // Cheek blush
    final blushPaint = Paint()..color = const Color(0xFFE8756A).withValues(alpha: 0.4);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.14, h * 0.07), blushPaint);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.68, h * 0.28, w * 0.14, h * 0.07), blushPaint);

    // Arms (wai gesture for happy/neutral)
    if (mood == MascotMood.happy || mood == MascotMood.neutral) {
      // Left arm going up in wai
      final leftArm = Path()
        ..moveTo(w * 0.22, h * 0.55)
        ..quadraticBezierTo(w * 0.05, h * 0.60, w * 0.28, h * 0.80);
      canvas.drawPath(leftArm, Paint()
        ..color = AppTheme.thaiRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.12
        ..strokeCap = StrokeCap.round);

      // Right arm going up in wai
      final rightArm = Path()
        ..moveTo(w * 0.78, h * 0.55)
        ..quadraticBezierTo(w * 0.95, h * 0.60, w * 0.72, h * 0.80);
      canvas.drawPath(rightArm, Paint()
        ..color = AppTheme.thaiRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.12
        ..strokeCap = StrokeCap.round);

      // Hands joined in wai
      canvas.drawOval(
          Rect.fromLTWH(w * 0.38, h * 0.76, w * 0.24, h * 0.12), skinPaint);
    } else if (mood == MascotMood.excited) {
      // Arms raised up
      _drawArm(canvas, Offset(w * 0.22, h * 0.55),
          Offset(w * 0.05, h * 0.35), AppTheme.thaiRed, w * 0.1);
      _drawArm(canvas, Offset(w * 0.78, h * 0.55),
          Offset(w * 0.95, h * 0.35), AppTheme.thaiRed, w * 0.1);
    } else if (mood == MascotMood.sad) {
      // Arms drooping down
      _drawArm(canvas, Offset(w * 0.22, h * 0.55),
          Offset(w * 0.08, h * 0.80), AppTheme.thaiRed, w * 0.1);
      _drawArm(canvas, Offset(w * 0.78, h * 0.55),
          Offset(w * 0.92, h * 0.80), AppTheme.thaiRed, w * 0.1);
      // Tear
      final tearPaint = Paint()..color = const Color(0xFF6AACFF);
      canvas.drawOval(
          Rect.fromLTWH(w * 0.62, h * 0.29, w * 0.05, h * 0.07), tearPaint);
    } else {
      // Encouraging — one arm up
      _drawArm(canvas, Offset(w * 0.22, h * 0.55),
          Offset(w * 0.05, h * 0.40), AppTheme.thaiRed, w * 0.1);
      _drawArm(canvas, Offset(w * 0.78, h * 0.55),
          Offset(w * 0.92, h * 0.70), AppTheme.thaiRed, w * 0.1);
    }

    // Gold details on body
    canvas.drawCircle(Offset(w * 0.5, h * 0.56), w * 0.04, goldPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.70), w * 0.03, goldPaint);
  }

  void _drawArm(Canvas canvas, Offset start, Offset end, Color color, double width) {
    canvas.drawLine(start, end, Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round);
  }

  void _drawEye(Canvas canvas, Offset center, double radius, MascotMood mood) {
    final whitePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF1A0A00);
    final highlightPaint = Paint()..color = Colors.white;

    if (mood == MascotMood.sad) {
      // Downward arched eye (sad)
      final path = Path()
        ..moveTo(center.dx - radius, center.dy)
        ..quadraticBezierTo(center.dx, center.dy + radius * 0.8, center.dx + radius, center.dy);
      canvas.drawPath(
          path, Paint()..color = const Color(0xFF1A0A00)..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      canvas.drawOval(
          Rect.fromCenter(center: center, width: radius * 2, height: radius * 1.4),
          whitePaint);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(center.dx, center.dy + (mood == MascotMood.excited ? -2 : 0)),
              width: radius * 1.0,
              height: radius * 1.1),
          pupilPaint);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(center.dx + radius * 0.2, center.dy - radius * 0.2),
              width: radius * 0.3,
              height: radius * 0.3),
          highlightPaint);
    }
  }

  void _drawMouth(Canvas canvas, Offset center, double width, MascotMood mood) {
    final paint = Paint()
      ..color = const Color(0xFF1A0A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (mood == MascotMood.happy || mood == MascotMood.excited) {
      // Big smile
      path.moveTo(center.dx - width / 2, center.dy);
      path.quadraticBezierTo(
          center.dx, center.dy + width * 0.5, center.dx + width / 2, center.dy);
    } else if (mood == MascotMood.sad) {
      // Frown
      path.moveTo(center.dx - width / 2, center.dy + width * 0.2);
      path.quadraticBezierTo(
          center.dx, center.dy - width * 0.3, center.dx + width / 2, center.dy + width * 0.2);
    } else {
      // Small smile / neutral
      path.moveTo(center.dx - width / 2, center.dy);
      path.quadraticBezierTo(
          center.dx, center.dy + width * 0.25, center.dx + width / 2, center.dy);
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
