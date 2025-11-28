import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/app/theme/theme_provider.dart';
import 'package:clothwise/src/features/recommendations/data/recommendation_service.dart';

/// Outfit detail screen - Shows the complete outfit with all selected items
class OutfitDetailScreen extends ConsumerWidget {
  const OutfitDetailScreen({
    required this.outfit,
    super.key,
  });

  final Map<String, dynamic> outfit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final recommendationService = RecommendationService();

    final imagePath = outfit['imagePath'] as String?;
    final description = outfit['description'] as String? ?? 'My Outfit';
    final selectedItems = outfit['selectedItems'] as List<dynamic>? ?? [];
    final timestamp = outfit['timestamp'] as String?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Outfit Details', style: theme.textTheme.headlineLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uploaded Photo Section
            if (imagePath != null && imagePath.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uploaded Photo',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? AppColors.shadowMediumDark : AppColors.shadowMedium,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        child: imagePath.startsWith('http')
                            ? Image.network(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholder(isDarkMode);
                                },
                              )
                            : Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholder(isDarkMode);
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),

            // Outfit Description
            Text(
              description,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (timestamp != null)
              Text(
                'Saved on ${_formatTimestamp(timestamp)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            // Selected Items Section
            Text(
              'Your Selected Items (${selectedItems.length})',
              style: AppTextStyles.sectionHeader.copyWith(
                color: theme.textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Items List
            if (selectedItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'No items selected',
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedItems.length,
                itemBuilder: (context, index) {
                  final item = selectedItems[index] as Map<String, dynamic>;
                  final itemName = item['name'] as String? ?? 'Unknown Item';
                  final itemCategory = item['category'] as String? ?? '';
                  final itemImageId = item['imageId'] as String? ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.cardRadius),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: recommendationService.getProductImageUrl(itemImageId),
                            height: 320,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 320,
                              color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 320,
                              color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Item Details
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    child: Text(
                                      'Item ${index + 1}',
                                      style: AppTextStyles.badge.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      itemCategory,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                itemName,
                                style: AppTextStyles.h3.copyWith(
                                  color: theme.textTheme.headlineSmall?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDarkMode) {
    return Container(
      color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
        }
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
