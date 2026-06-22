import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../models/word.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';

enum _CardSide { thai, english }
enum _CardState { idle, selected, matched, wrong }

class _PairCard {
  final Word word;
  final _CardSide side;
  _CardState state;
  _PairCard(this.word, this.side, {this.state = _CardState.idle});
}

class PairsScreen extends StatefulWidget {
  final MatchPairExercise exercise;
  final void Function(bool) onComplete;
  final bool answered;

  const PairsScreen({
    super.key,
    required this.exercise,
    required this.onComplete,
    required this.answered,
  });

  @override
  State<PairsScreen> createState() => _PairsScreenState();
}

class _PairsScreenState extends State<PairsScreen> {
  late List<_PairCard> _thaiCards;
  late List<_PairCard> _engCards;
  _PairCard? _selectedThai;
  _PairCard? _selectedEng;
  int _matched = 0;
  int _mistakes = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final words = List<Word>.from(widget.exercise.pairs)..shuffle();
    _thaiCards = words.map((w) => _PairCard(w, _CardSide.thai)).toList();
    final engWords = List<Word>.from(words)..shuffle();
    _engCards = engWords.map((w) => _PairCard(w, _CardSide.english)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MATCH THE PAIRS',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const Text('Tap a Thai word, then its English meaning',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: _thaiCards
                      .asMap()
                      .entries
                      .map((e) => _buildCard(e.value, e.key))
                      .toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: _engCards
                      .asMap()
                      .entries
                      .map((e) => _buildCard(e.value, e.key))
                      .toList(),
                ),
              ),
            ],
          ),
          if (_completed)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉 ', style: TextStyle(fontSize: 24)),
                  Text(
                    _mistakes == 0 ? 'Perfect!' : 'All matched!',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: AppTheme.success),
                  ),
                ],
              ).animate().scale(curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(_PairCard card, int index) {
    Color bg, borderColor, textColor;
    switch (card.state) {
      case _CardState.selected:
        bg = const Color(0xFFEEF8FF);
        borderColor = AppTheme.primary;
        textColor = AppTheme.primary;
        break;
      case _CardState.matched:
        bg = const Color(0xFFE8FAD8);
        borderColor = AppTheme.success;
        textColor = const Color(0xFF2D7A00);
        break;
      case _CardState.wrong:
        bg = const Color(0xFFFFE0E0);
        borderColor = AppTheme.danger;
        textColor = const Color(0xFFA80000);
        break;
      default:
        bg = AppTheme.card;
        borderColor = AppTheme.border;
        textColor = AppTheme.textPrimary;
    }

    final isThai = card.side == _CardSide.thai;
    final label = isThai ? card.word.thai : card.word.english;
    final sublabel = isThai ? card.word.phonetic : null;

    return GestureDetector(
      onTap: card.state == _CardState.matched ? null : () => _tap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: isThai ? 22 : 15,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            if (sublabel != null)
              Text(sublabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: textColor.withOpacity(0.7))),
          ],
        ),
      ),
    )
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 300.ms)
        .slideX(
            begin: isThai ? -0.1 : 0.1,
            duration: 300.ms,
            curve: Curves.easeOut);
  }

  void _tap(_PairCard card) {
    if (_completed) return;
    if (card.side == _CardSide.thai) {
      if (_selectedThai == card) {
        setState(() { card.state = _CardState.idle; _selectedThai = null; });
        return;
      }
      _selectedThai?.state = _CardState.idle;
      setState(() { _selectedThai = card; card.state = _CardState.selected; });
    } else {
      if (_selectedEng == card) {
        setState(() { card.state = _CardState.idle; _selectedEng = null; });
        return;
      }
      _selectedEng?.state = _CardState.idle;
      setState(() { _selectedEng = card; card.state = _CardState.selected; });
    }
    _checkMatch();
  }

  void _checkMatch() {
    if (_selectedThai == null || _selectedEng == null) return;
    final thai = _selectedThai!;
    final eng = _selectedEng!;
    if (thai.word.id == eng.word.id) {
      AudioService().playCorrect();
      setState(() {
        thai.state = _CardState.matched;
        eng.state = _CardState.matched;
        _selectedThai = null;
        _selectedEng = null;
        _matched++;
      });
      if (_matched == widget.exercise.pairs.length) {
        setState(() => _completed = true);
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onComplete(_mistakes == 0);
        });
      }
    } else {
      _mistakes++;
      setState(() {
        thai.state = _CardState.wrong;
        eng.state = _CardState.wrong;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          thai.state = _CardState.idle;
          eng.state = _CardState.idle;
          _selectedThai = null;
          _selectedEng = null;
        });
      });
    }
  }
}
