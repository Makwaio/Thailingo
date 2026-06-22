import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/user_service.dart';
import '../ui/theme/app_theme.dart';
import 'home_screen.dart';

const _avatarOptions = [
  '🐘', '🐯', '🦋', '🌺', '🎋', '🏯', '🐉', '🦜',
  '🌴', '🎭', '🍜', '🥊', '🎪', '🌙', '⭐', '🔥',
  '💎', '🏆', '🎯', '🎨',
];

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String name;

  const ProfileSetupScreen({super.key, required this.uid, required this.name});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late TextEditingController _nameCtrl;
  String _selectedAvatar = _avatarOptions.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await UserService()
          .setAvatarAndUsername(widget.uid, _selectedAvatar, name);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.thaiNavyDk, AppTheme.thaiNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedAvatar,
                    style: const TextStyle(fontSize: 72),
                  ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose your avatar!',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick an emoji that represents you',
                    style: TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                ],
              ),
            ),
            // Avatar grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _avatarOptions.length,
                      itemBuilder: (_, i) {
                        final emoji = _avatarOptions[i];
                        final selected = emoji == _selectedAvatar;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedAvatar = emoji),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.thaiNavy
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.thaiGold
                                    : Colors.grey.withValues(alpha: 0.3),
                                width: selected ? 2.5 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.thaiNavy
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 30)),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Username field
                    const Text(
                      'Your name',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: 'Enter your display name',
                        filled: true,
                        fillColor: Colors.white,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(
                              color: AppTheme.thaiNavy, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.thaiNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          elevation: 4,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text(
                                'Start Learning! 🎉',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
