import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../flights/presentation/providers/flights_providers.dart';
import '../../../shell/presentation/screens/app_navigation_shell.dart';
import '../../../backups/data/backup_intent_service.dart';

/// Professional aviation splash and pre-warm screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  Timer? _navTimer;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    // Pre-warm database and flights repository
    ref.read(flightsRepositoryProvider);

    // Smooth transition to main logbook screen after brief splash
    _navTimer = Timer(const Duration(milliseconds: 1400), _navigateToHome);
  }

  Future<void> _navigateToHome() async {
    if (!mounted || _navigating) return;
    _navigating = true;
    _navTimer?.cancel();

    // Check if cold-started with a backup archive
    final pendingPath = await BackupIntentService.getPendingBackupPath();
    if (!mounted) return;

    final navigator = Navigator.of(context);
    // Route futures complete when the destination closes, not when it opens.
    unawaited(
      navigator.pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, anim, secondaryAnim) =>
              const AppNavigationShell(),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
    );

    if (pendingPath != null && pendingPath.isNotEmpty) {
      unawaited(
        navigator.pushNamed(AppRouter.backupsRoute, arguments: pendingPath),
      );
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matches splash_background / ic_launcher_background on Android.
      backgroundColor: const Color(0xFF0F1A2B),
      body: InkWell(
        onTap: _navigateToHome, // Allow quick tap-to-skip
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // Same artwork and navy as the launcher icon and the
                        // native splash, so the hand-off is seamless.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 96,
                            height: 96,
                            cacheWidth: (96 *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // App Title
                        const Text(
                          'Spreadlog',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Text(
                            'PROFESSIONAL DIGITAL LOGBOOK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Subtle progress indicator
                        SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              minHeight: 2.5,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'PREPARING FLIGHT DECK...',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
