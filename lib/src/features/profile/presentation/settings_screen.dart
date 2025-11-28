import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';

/// Settings screen - Full screen version of settings
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Settings', style: theme.textTheme.headlineLarge),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SettingsItem(
            icon: Icons.view_carousel_outlined,
            title: 'Canvas View - All Screens',
            subtitle: 'View all app screens',
            onTap: () {
              // TODO: Navigate to canvas view
            },
          ),
          _SettingsItem(
            icon: Icons.photo_library_outlined,
            title: 'Screen Gallery',
            subtitle: 'Browse screen designs',
            onTap: () {
              // TODO: Navigate to screen gallery
            },
          ),
          _SettingsItem(
            icon: Icons.account_circle_outlined,
            title: 'Account Settings',
            subtitle: 'Manage your account',
            onTap: () {
              // TODO: Navigate to account settings
            },
          ),
          _SettingsItem(
            icon: Icons.style_outlined,
            title: 'Style Preferences',
            subtitle: 'Customize your style',
            onTap: () {
              // TODO: Navigate to style preferences
            },
          ),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            subtitle: 'Manage notifications',
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          const Divider(height: AppSpacing.xl),
          _SettingsItem(
            icon: Icons.science_outlined,
            title: 'View Classify Result (Demo)',
            subtitle: 'See classification demo',
            onTap: () {
              // TODO: Show demo
            },
          ),
          _SettingsItem(
            icon: Icons.view_list_outlined,
            title: 'View Empty States (Demo)',
            subtitle: 'Preview empty states',
            onTap: () {
              // TODO: Show empty states
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? AppColors.shadowLightDark : AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }
}
