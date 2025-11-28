import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/app/theme/theme_provider.dart';
import 'package:clothwise/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:clothwise/src/features/wardrobe/presentation/providers/wardrobe_providers.dart';
import 'package:intl/intl.dart';

/// Profile screen (Screens 13-14) - User stats and settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final theme = Theme.of(context);

    // Watch auth state for user data
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    // Watch wardrobe items for count
    final wardrobeState = ref.watch(backendProductsProvider);

    // Generate random style score (85-100%)
    final styleScore = 85 + Random().nextInt(16); // 85 to 100

    // Get username or fallback to email
    final displayName = user?.username ?? user?.email.split('@').first ?? 'User';

    // Format member since date
    String memberSince = 'Member since Oct 2024'; // Default
    if (user?.createdAt != null) {
      memberSince = 'Member since ${DateFormat('MMM yyyy').format(user!.createdAt!)}';
    }

    // Get item count
    final itemCount = wardrobeState.when(
      data: (items) => items.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Settings', style: theme.textTheme.headlineLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Profile header card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? AppColors.shadowMediumDark : AppColors.shadowMedium,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar and name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.h3.copyWith(
                                color: theme.textTheme.headlineMedium?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              memberSince,
                              style: AppTextStyles.caption.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(itemCount.toString(), 'Items', theme),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDarkMode ? AppColors.dividerDark : AppColors.divider,
                      ),
                      _buildStatItem('0', 'Outfits', theme),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDarkMode ? AppColors.dividerDark : AppColors.divider,
                      ),
                      _buildStatItem('$styleScore%', 'Style Score', theme),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Dark Mode Toggle
            _buildSettingCard(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDarkMode ? 'On' : 'Off',
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                    activeColor: AppColors.primaryBrownDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Gender preference
            _buildSettingCard(
              context,
              icon: Icons.person_outline,
              title: 'Gender',
              child: _GenderToggle(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Default city
            _buildSettingCard(
              context,
              icon: Icons.location_on_outlined,
              title: 'Default City',
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Cairo',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Notifications Toggle
            _buildSettingCard(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Get notified about new recommendations and outfit updates',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const _NotificationToggle(),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Support & FAQ section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Support & FAQ',
                style: AppTextStyles.sectionHeader.copyWith(
                  color: theme.textTheme.headlineMedium?.color,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            const _FAQSection(),

            const SizedBox(height: AppSpacing.xl),

            // Data Management section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Data Management',
                style: AppTextStyles.sectionHeader.copyWith(
                  color: theme.textTheme.headlineMedium?.color,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Clear wardrobe button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Clear wardrobe with confirmation
              },
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Clear Wardrobe'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                foregroundColor: isDarkMode ? AppColors.errorDark : AppColors.error,
                side: BorderSide(
                  color: isDarkMode ? AppColors.errorDark : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: theme.textTheme.headlineLarge?.color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowMediumDark : AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.secondary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: theme.textTheme.headlineMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _GenderToggle extends StatefulWidget {
  @override
  State<_GenderToggle> createState() => _GenderToggleState();
}

class _GenderToggleState extends State<_GenderToggle> {
  String _selectedGender = 'Male';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = 'Male';
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedGender == 'Male'
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Male',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: _selectedGender == 'Male'
                        ? theme.colorScheme.onPrimary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = 'Female';
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedGender == 'Female'
                      ? (isDark ? AppColors.femaleColorDark : AppColors.femaleColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Female',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: _selectedGender == 'Female'
                        ? (isDark ? AppColors.backgroundDark : AppColors.cardBackground)
                        : theme.textTheme.bodyMedium?.color,
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

/// Notification toggle widget
class _NotificationToggle extends StatefulWidget {
  const _NotificationToggle();

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _notificationsEnabled,
      onChanged: (value) {
        setState(() {
          _notificationsEnabled = value;
        });
        // TODO: Save notification preference
      },
      activeColor: AppColors.primaryBrownDark,
    );
  }
}

/// FAQ Section widget
class _FAQSection extends StatelessWidget {
  const _FAQSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FAQItem(
          question: 'How do I get outfit recommendations?',
          answer: 'Simply upload a photo of a clothing item from your gallery or take a new photo with your camera. Our AI will analyze the item and provide personalized outfit recommendations that match your style.',
        ),
        SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'How do I save outfits?',
          answer: 'After viewing AI recommendations, tap on the items you like to select them (you\'ll see a checkmark). Then press the "Save" button at the top to save your custom outfit.',
        ),
        SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'Where can I see my saved outfits?',
          answer: 'Go to the Home screen and scroll down to "Last Outfits You Chose" section. Tap any outfit card to view the complete outfit with all selected items.',
        ),
        SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'How does the AI recommendation work?',
          answer: 'Our AI analyzes the clothing item you upload (color, style, category) and suggests matching pieces from our catalog. It considers fashion rules, color harmony, and style compatibility.',
        ),
        SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'Can I change between light and dark mode?',
          answer: 'Yes! Toggle the Dark Mode switch in Settings to switch between light and dark themes based on your preference.',
        ),
        SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'What should I do if recommendations fail to load?',
          answer: 'Make sure you have a stable internet connection and that the backend server is running. If the issue persists, try uploading a different photo with better lighting.',
        ),
      ],
    );
  }
}

/// FAQ Item widget with expandable answer
class _FAQItem extends StatefulWidget {
  const _FAQItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.borderLightDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg + 28,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                widget.answer,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
