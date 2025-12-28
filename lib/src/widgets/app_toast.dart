import 'package:flutter/material.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';

/// Toast notification types
enum ToastType {
  success,
  error,
  info,
  warning,
}

/// App-wide toast notification utility
class AppToast {
  /// Show a success toast
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, ToastType.success);
  }

  /// Show an error toast
  static void showError(BuildContext context, String message) {
    _showToast(context, message, ToastType.error);
  }

  /// Show an info toast
  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, ToastType.info);
  }

  /// Show a warning toast
  static void showWarning(BuildContext context, String message) {
    _showToast(context, message, ToastType.warning);
  }

  /// Internal method to show toast with customization
  static void _showToast(
    BuildContext context,
    String message,
    ToastType type,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get colors based on type
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green.shade600;
        iconColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case ToastType.error:
        backgroundColor = Colors.red.shade600;
        iconColor = Colors.white;
        icon = Icons.error;
        break;
      case ToastType.warning:
        backgroundColor = Colors.orange.shade600;
        iconColor = Colors.white;
        icon = Icons.warning;
        break;
      case ToastType.info:
        backgroundColor = isDark ? AppColors.primaryBrownDark : AppColors.primaryBrown;
        iconColor = Colors.white;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyRegular.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
