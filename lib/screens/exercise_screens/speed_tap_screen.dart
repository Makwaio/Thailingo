import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';

class SpeedTapScreen extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool correct, {int bonusXp}) onAnswer;
  final bool answered;
  final bool lastCorrect;

  const SpeedTapScreen({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.answered,
    required this.lastCorrect,
  });

  @override
  State<SpeedTapScreen> createState() => _SpeedTapScreenState();
}

class _SpeedTapScreenState extends State<SpeedTapScreen>
    with SingleTickerProviderStateMixin {
  static const _totalSeconds = 5;
  late Timer _timer;
  double _timeLeft = _totalSeconds.toDouble();
  bool _answered = false;
  String? _selectedId;
  String? _flashLabel;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(SpeedTapScreen old) {
    super.didUpdateWidget(old);
    if (!old.answered && widget.answered) {
      _timer.cancel();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeLeft -= 0.1;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          t.cancel();
          if (!_answered) {
            _answered = true;
            widget.onAnswer(false, bonusXp: 0);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  int _calcBonusXp(double timeUsed) {
    final ratio = 1.0 - (timeUsed / _totalSeconds);
    return (5 + (ratio * 15)).round().clamp(5, 20);
  }

  void _onTap(String wordId) {
    if (_answered || widget.answered) return;
    AudioService().playClick();
    _timer.cancel();
    final timeUsed = _totalSeconds - _timeLeft;
    final correct = wordId == widget.exercise.targetWord.id;
    final bonus = correct ? _calcBonusXp(timeUsed) : 0;

    setState(() {
      _answered = true;
      _selectedId = wordId;
      if (correct) {
        final ratio = 1.0 - (timeUsed / _totalSeconds);
        if (ratio > 0.8) _flashLabel = '⚡ LIGHTNING!';
        else if (ratio > 0.6) _flashLabel = '🔥 FAST!';
        else if (ratio > 0.4) _flashLabel = '🌟 NICE!';
      }
    });

    if (correct) AudioService().playCorrect();
    widget.onAnswer(correct, bonusXp: bonus);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.exercise.targetWord;
    final showThai = DateTime.now().millisecondsSinceEpoch % 2 == 0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Timer bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: _timeLeft / _totalSeconds,
              minHeight: 8,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                _timeLeft > 2
                    ? AppTheme.success
                    : _timeLeft > 1
                        ? AppTheme.thaiGold
                        : AppTheme.thaiRed,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_timeLeft.toStringAsFixed(1)}s',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _timeLeft <= 1 ? AppTheme.thaiRed : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Prompt word
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: AppTheme.thaiNavy,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.thaiNavy.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  showThai ? target.thai : target.english,
                  style: TextStyle(
                    fontSize: showThai ? 36 : 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showThai)
                  Text(
                    target.phonetic,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),

          if (_flashLabel != null)
            Text(
              _flashLabel!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.thaiGold,
              ),
            )
                .animate(key: ValueKey(_flashLabel))
                .scale(begin: const Offset(0.5, 0.5), duration: 300.ms)
                .fadeIn(duration: 200.ms),

          const SizedBox(height: 24),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: widget.exercise.options.map((opt) {
                Color bg;
                Color border;
                if (!_answered && !widget.answered) {
                  bg = Colors.white;
                  border = AppTheme.border;
                } else if (opt.id == widget.exercise.targetWord.id) {
                  bg = AppTheme.success.withOpacity(0.1);
                  border = AppTheme.success;
                } else if (opt.id == _selectedId) {
                  bg = AppTheme.thaiRed.withOpacity(0.1);
                  border = AppTheme.thaiRed;
                } else {
                  bg = Colors.white;
                  border = AppTheme.border;
                }

                return GestureDetector(
                  onTap: () => _onTap(opt.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: border, width: 2),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          showThai ? opt.english : opt.thai,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (!showThai)
                          Text(
                            opt.phonetic,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
