import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:clothwise/src/app/router.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/core/services/preferences_service.dart';

/// Splash screen (Screen 1) - Auto-navigates based on app state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnState();
  }

  Future<void> _navigateBasedOnState() async {
    // Wait for splash screen to show
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user has completed onboarding
    final hasCompletedOnboarding = await PreferencesService.hasCompletedOnboarding();

    if (!mounted) return;

    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    // Navigate based on state
    if (!hasCompletedOnboarding) {
      // First time user - show onboarding
      context.go(RoutePaths.onboarding);
    } else if (user == null) {
      // User has seen onboarding but not logged in
      context.go(RoutePaths.login);
    } else {
      // User is logged in - go to home
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primaryBrown,
                        child: const Center(
                          child: Icon(
                            Icons.dry_cleaning,
                            size: 56,
                            color: AppColors.cardBackground,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // App name
              const Text(
                'ClothWise',
                style: AppTextStyles.h1,
              ),

              const SizedBox(height: AppSpacing.sm),

              // Tagline
              const Text(
                'AI outfits, styled for the weather.',
                style: AppTextStyles.tagline,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBrown),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
