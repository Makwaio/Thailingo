import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ui/theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/settings_service.dart';
import 'services/firebase_service.dart';
import 'services/user_service.dart';
import 'services/progress_service.dart';
import 'services/bug_report_service.dart';
import 'services/patch_notes_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await SettingsService().load();
  BugReportService().retryPendingReports();
  await PatchNotesService().seedInitialPatchNotes();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ThailingoApp());
}

class ThailingoApp extends StatelessWidget {
  const ThailingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thailingo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final firebaseService = FirebaseService();
    Widget destination;

    if (firebaseService.isSignedIn()) {
      final uid = firebaseService.getUserId()!;
      await UserService().resetWeeklyXpIfNeeded(uid);
      final isSetup = await UserService().isProfileSetup(uid);
      if (!mounted) return;
      if (!isSetup) {
        destination = ProfileSetupScreen(
          uid: uid,
          name: firebaseService.getUserName() ?? 'Learner',
        );
      } else {
        final localProgress = await ProgressService().load();
        await UserService().syncLocalProgress(uid, localProgress);
        destination = const MainShell();
      }
    } else {
      destination = const LoginScreen();
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Thai flag stripe pattern
          Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(color: AppTheme.thaiRed),
              ),
              Expanded(
                flex: 3,
                child: Container(color: Colors.white),
              ),
              Expanded(
                flex: 4,
                child: Container(color: AppTheme.thaiNavy),
              ),
              Expanded(
                flex: 3,
                child: Container(color: Colors.white),
              ),
              Expanded(
                flex: 2,
                child: Container(color: AppTheme.thaiRed),
              ),
            ],
          ),
          // Centered logo overlay
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.thaiNavy,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXl),
                          border: Border.all(
                              color: AppTheme.thaiGold, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.thaiNavy.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🇹🇭',
                              style: TextStyle(fontSize: 60)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Thailingo',
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.thaiNavy,
                              letterSpacing: -1)),
                      const SizedBox(height: 8),
                      const Text('Bangkok Thai — Learn & Play',
                          style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.thaiNavy,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 40, height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.thaiNavy.withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
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
