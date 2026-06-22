import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import '../services/progress_service.dart';
import '../ui/theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final credential = await FirebaseService().signInWithGoogle();
      if (!mounted) return;
      if (credential == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in cancelled')),
        );
        return;
      }

      final uid = credential.user!.uid;
      final name = credential.user!.displayName ?? 'Learner';
      final email = credential.user!.email ?? '';

      await UserService().createUserProfile(uid, name, email);
      if (!mounted) return;

      final isSetup = await UserService().isProfileSetup(uid);
      if (!mounted) return;

      if (!isSetup) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(uid: uid, name: name),
          ),
        );
      } else {
        final localProgress = await ProgressService().load();
        await UserService().syncLocalProgress(uid, localProgress);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Thai flag stripe background
          Column(
            children: [
              Expanded(flex: 2, child: Container(color: AppTheme.thaiRed)),
              Expanded(flex: 3, child: Container(color: Colors.white)),
              Expanded(flex: 4, child: Container(color: AppTheme.thaiNavy)),
              Expanded(flex: 3, child: Container(color: Colors.white)),
              Expanded(flex: 2, child: Container(color: AppTheme.thaiRed)),
            ],
          ),
          // Frosted overlay
          Container(color: Colors.black.withValues(alpha: 0.18)),
          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: AppTheme.thaiNavy,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.thaiGold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🇹🇭', style: TextStyle(fontSize: 54)),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.7, 0.7)),
                const SizedBox(height: 20),
                const Text(
                  'Thailingo',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.thaiGold.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Text(
                    'ยินดีต้อนรับ! Welcome!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.thaiNavy,
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                const SizedBox(height: 10),
                const Text(
                  'Sign in to compete with friends on the leaderboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
                const Spacer(flex: 2),
                // Google Sign In button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GestureDetector(
                    onTap: _loading ? null : _signInWithGoogle,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_loading)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.thaiNavy),
                            )
                          else ...[
                            const _GoogleG(),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 550.ms, duration: 500.ms).slideY(
                    begin: 0.3, delay: 550.ms, duration: 500.ms),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : _continueAsGuest,
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white54,
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                const SizedBox(height: 6),
                const Text(
                  'Guests can play but cannot join the leaderboard',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Google 'G' logo widget
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF4285F4),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
