import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clothwise/src/app/router.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/widgets/app_button.dart';
import 'package:clothwise/src/features/auth/presentation/providers/auth_providers.dart';

/// Email Verification Screen
/// Shows after user registers - prompts them to verify their email
/// User should check their email inbox and click the verification link
/// Can manually check verification status or resend email
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isCheckingVerification = false;
  bool _isResending = false;
  Timer? _autoCheckTimer;
  int _secondsUntilNextResend = 0;
  Timer? _resendCooldownTimer;

  @override
  void initState() {
    super.initState();
    // Auto-check verification status every 5 seconds
    _startAutoCheck();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  /// Start auto-checking email verification status every 5 seconds
  void _startAutoCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkEmailVerification(silent: true);
    });
  }

  /// Check if email has been verified
  /// If verified, navigate to home screen
  /// If silent=true, don't show loading spinner (for auto-checks)
  Future<void> _checkEmailVerification({bool silent = false}) async {
    if (!silent) {
      setState(() => _isCheckingVerification = true);
    }

    final isVerified =
        await ref.read(authNotifierProvider.notifier).checkEmailVerified();

    if (!silent) {
      setState(() => _isCheckingVerification = false);
    }

    if (mounted) {
      if (isVerified) {
        // Email verified! Stop auto-checking and navigate to home
        _autoCheckTimer?.cancel();
        _showSuccessDialog();
      } else if (!silent) {
        // Not verified yet - show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show success dialog when email is verified
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Email Verified!',
              style: AppTextStyles.h3,
            ),
          ],
        ),
        content: Text(
          'Your email has been successfully verified. You can now use all features of ClothWise.',
          style: AppTextStyles.bodyRegular.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Get Started',
              onPressed: () {
                Navigator.of(context).pop();
                context.go(RoutePaths.home);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Resend verification email
  /// Has 60-second cooldown to prevent spam
  Future<void> _resendVerificationEmail() async {
    if (_secondsUntilNextResend > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait $_secondsUntilNextResend seconds before resending',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isResending = true);

    await ref.read(authNotifierProvider.notifier).sendVerificationEmail();

    setState(() => _isResending = false);

    // Check for errors
    final authState = ref.read(authNotifierProvider);

    if (mounted) {
      if (authState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Success - show message and start cooldown
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 3),
          ),
        );

        // Start 60-second cooldown
        _startResendCooldown();
      }
    }
  }

  /// Start 60-second cooldown timer for resend button
  void _startResendCooldown() {
    setState(() => _secondsUntilNextResend = 60);

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsUntilNextResend--;
        if (_secondsUntilNextResend <= 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userEmail = authState.user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBrown),
          onPressed: () {
            // Sign out and go back to login
            ref.read(authNotifierProvider.notifier).signOut();
            context.go(RoutePaths.login);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Email icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: AppColors.primaryBrown,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Title
              const Text(
                'Verify Your Email',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              // Instructions
              Text(
                'We sent a verification link to:',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              // User's email
              Text(
                userEmail,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryBrown,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Info card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.accentBrown,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'How to verify:',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryBrown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildStep('1', 'Open your email inbox'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStep('2', 'Find the verification email from ClothWise'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStep('3', 'Click the verification link'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStep('4', 'Return here and check verification status'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Check verification button
              AppButton(
                label: 'I Verified My Email',
                onPressed: () => _checkEmailVerification(),
                isLoading: _isCheckingVerification,
              ),

              const SizedBox(height: AppSpacing.md),

              // Resend email button
              AppButton(
                label: _secondsUntilNextResend > 0
                    ? 'Resend Email ($_secondsUntilNextResend)'
                    : 'Resend Verification Email',
                onPressed: _resendVerificationEmail,
                type: AppButtonType.secondary,
                isLoading: _isResending,
              ),

              const SizedBox(height: AppSpacing.md),

              // Skip verification for demo/testing
              TextButton(
                onPressed: () {
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.cardBackground,
                      title: Text(
                        'Skip Verification?',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      content: Text(
                        'This will let you access the app without verifying your email. '
                        'Only use this for testing or demo purposes.',
                        style: AppTextStyles.bodyRegular.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        AppButton(
                          label: 'Skip for Now',
                          fullWidth: false,
                          onPressed: () {
                            Navigator.pop(context);
                            context.go(RoutePaths.home);
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Skip Verification (Demo Mode)',
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Auto-check indicator
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.summerBadgeBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.summerBadgeText,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Auto-checking verification status...',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.summerBadgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a step indicator widget
  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.cardBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
