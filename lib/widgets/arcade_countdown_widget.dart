import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../ui/widgets/thai_mascot.dart';

class ArcadeCountdownWidget extends StatefulWidget {
  final String gameEmoji;
  final String gameTitle;
  final String instruction;
  final int? bestScore;
  final VoidCallback onStart;

  const ArcadeCountdownWidget({
    super.key,
    required this.gameEmoji,
    required this.gameTitle,
    required this.instruction,
    this.bestScore,
    required this.onStart,
  });

  @override
  State<ArcadeCountdownWidget> createState() => _ArcadeCountdownWidgetState();
}

class _ArcadeCountdownWidgetState extends State<ArcadeCountdownWidget>
    with TickerProviderStateMixin {
  bool _counting = false;
  int _count = 3;
  Timer? _timer;

  late final AnimationController _pulseCtrl;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 1.5, end: 0.85)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onPlay() {
    AudioService().playClick();
    setState(() {
      _counting = true;
      _count = 3;
    });
    _scaleCtrl.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_count <= 1) {
        t.cancel();
        setState(() => _count = 0);
        AudioService().playCorrect();
        _scaleCtrl.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onStart();
        });
      } else {
        setState(() => _count--);
        AudioService().playClick();
        _scaleCtrl.forward(from: 0);
      }
    });
  }

  Color get _countColor {
    switch (_count) {
      case 3:
        return const Color(0xFFF44336);
      case 2:
        return const Color(0xFFFF9800);
      case 1:
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      body: SafeArea(
        child: _counting ? _buildCountdown() : _buildStartScreen(),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BobbingMascot(size: 72, mood: MascotMood.excited),
          const SizedBox(height: 16),
          Text(widget.gameEmoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          Text(
            widget.gameTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.instruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => GestureDetector(
              onTap: _onPlay,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFB5001C),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB5001C).withValues(
                          alpha: 0.3 + 0.25 * _pulseCtrl.value),
                      blurRadius: 20 + 12 * _pulseCtrl.value,
                      spreadRadius: 2 + 3 * _pulseCtrl.value,
                    ),
                  ],
                ),
                child: const Text(
                  'PLAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
          if (widget.bestScore != null && widget.bestScore! > 0) ...[
            const SizedBox(height: 16),
            Text(
              'Best: ${widget.bestScore} pts',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 36),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '← Back',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, __) {
          final s = _scaleAnim.value;
          final text = _count == 0 ? 'GO!' : '$_count';
          return SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 180 * s,
                  height: 180 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _countColor.withValues(
                      alpha: (0.15 * (1.0 - _scaleCtrl.value * 0.5))
                          .clamp(0.0, 1.0),
                    ),
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(
                    color: _countColor,
                    fontSize: (120 * s).clamp(60.0, 180.0),
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: _countColor.withValues(alpha: 0.55),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
