import 'package:flutter/material.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';

/// Dialog shown after capturing a photo, asking user what to do with it
class CameraActionDialog extends StatelessWidget {
  final VoidCallback onAddToWardrobe;
  final VoidCallback onGetRecommendations;

  const CameraActionDialog({
    super.key,
    required this.onAddToWardrobe,
    required this.onGetRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'What would you like to do?',
              style: AppTextStyles.h3.copyWith(
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Choose an action for this photo',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Add to Wardrobe Button
            _ActionButton(
              icon: Icons.checkroom,
              label: 'Add to Wardrobe',
              subtitle: 'Save this item to your collection',
              onTap: () {
                Navigator.of(context).pop();
                onAddToWardrobe();
              },
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),

            // Get Recommendations Button
            _ActionButton(
              icon: Icons.auto_awesome,
              label: 'Get Recommendations',
              subtitle: 'Find matching outfits',
              onTap: () {
                Navigator.of(context).pop();
                onGetRecommendations();
              },
              isDarkMode: isDarkMode,
              isPrimary: true,
            ),
            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDarkMode;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isDarkMode,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDarkMode ? AppColors.accentBrown : AppColors.primaryBrown;
    final backgroundColor = isPrimary
        ? primaryColor
        : isDarkMode
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackground;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? primaryColor
                  : isDarkMode
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.2)
                      : AppColors.textSecondary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.2)
                      : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 16,
                        color: isPrimary
                            ? Colors.white
                            : isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.8)
                            : isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isPrimary
                    ? Colors.white
                    : isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
