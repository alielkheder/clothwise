import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clothwise/src/app/router.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/app/theme/theme_provider.dart';
import 'package:clothwise/src/widgets/app_text_field.dart';
import 'package:clothwise/src/features/wardrobe/presentation/providers/wardrobe_providers.dart';
import 'package:clothwise/src/features/wardrobe/presentation/widgets/camera_action_dialog.dart';
import 'package:clothwise/src/features/wardrobe/data/local_wardrobe_storage.dart';
import 'package:clothwise/src/features/home/domain/entities/clothing_item.dart';

/// Wardrobe screen (Screens 9-10) - User's clothing collection
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String _selectedCategory = 'All';
  final _imagePicker = ImagePicker();
  final _wardrobeStorage = LocalWardrobeStorage();

  final List<String> _categories = [
    'All',
    'Topwear',
    'Bottomwear',
    'One-piece',
    'Footwear',
  ];

  /// Capture photo from camera
  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        _showActionDialog(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  /// Show dialog asking what to do with the captured photo
  void _showActionDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => CameraActionDialog(
        onAddToWardrobe: () => _addToWardrobe(imagePath),
        onGetRecommendations: () => _getRecommendations(imagePath),
      ),
    );
  }

  /// Add photo to wardrobe
  Future<void> _addToWardrobe(String imagePath) async {
    // TODO: Show form to get item details (name, category, etc.)
    // For now, just save with default values
    try {
      await _wardrobeStorage.saveItem(
        imagePath: imagePath,
        name: 'New Item',
        category: 'Topwear',
        styleType: 'casual',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to wardrobe!')),
        );
        // Refresh wardrobe items
        ref.invalidate(backendProductsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    }
  }

  /// Navigate to recommendations screen with the captured photo
  void _getRecommendations(String imagePath) {
    // Navigate to recommendations screen with the photo
    context.go(RoutePaths.recommendations, extra: imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('My Wardrobe', style: theme.textTheme.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.go(RoutePaths.profile);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: AppSearchField(
              hintText: 'Search items...',
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),

          // Category filters
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: theme.cardTheme.color,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: AppTextStyles.badge.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDarkMode ? AppColors.borderLightDark : AppColors.borderLight),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                );
              },
            ),
          ),

          // Wardrobe items grid
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                // Watch backend products instead of wardrobe items
                final backendProductsState = ref.watch(backendProductsProvider);

                return backendProductsState.when(
                  data: (items) {
                    // Filter items by category
                    final filteredItems = _selectedCategory == 'All'
                        ? items
                        : items.where((item) {
                            return item.category.displayName == _selectedCategory;
                          }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.checkroom_outlined,
                              size: 64,
                              color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No items in your wardrobe',
                              style: AppTextStyles.bodyRegular.copyWith(
                                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap + to add your first item',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _WardrobeItemCard(
                          item: item,
                          // onTap disabled - only get AI recommendations from camera/gallery
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Error loading items',
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          error.toString(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _capturePhoto,
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.camera_alt, color: theme.colorScheme.onPrimary),
      ),
    );
  }
}

class _WardrobeItemCard extends StatelessWidget {
  const _WardrobeItemCard({
    required this.item,
  });

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
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
          // Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardRadius),
                ),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.cardRadius),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.error_outline,
                            color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.checkroom_outlined,
                        size: 48,
                        color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                    ),
            ),
          ),

          // Item details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.itemName.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.usage.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getColorFromName(item.color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        item.color,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    final lowerColor = colorName.toLowerCase();

    // Common colors
    if (lowerColor.contains('blue')) return Colors.blue;
    if (lowerColor.contains('red')) return Colors.red;
    if (lowerColor.contains('green')) return Colors.green;
    if (lowerColor.contains('yellow')) return Colors.yellow;
    if (lowerColor.contains('orange')) return Colors.orange;
    if (lowerColor.contains('purple') || lowerColor.contains('violet')) return Colors.purple;
    if (lowerColor.contains('pink')) return Colors.pink;
    if (lowerColor.contains('brown')) return Colors.brown;
    if (lowerColor.contains('black')) return Colors.black;
    if (lowerColor.contains('white')) return Colors.white;
    if (lowerColor.contains('grey') || lowerColor.contains('gray')) return Colors.grey;

    return AppColors.borderLight;
  }
}
