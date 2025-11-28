import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clothwise/src/app/router.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/app/theme/theme_provider.dart';
import 'package:clothwise/src/features/shop/data/shop_service.dart';
import 'package:clothwise/src/features/shop/presentation/providers/shop_providers.dart';

/// Shop screen - Shopping suggestions with real products
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _selectedPriceFilter = 'All';
  String? _selectedCategory;
  String? _selectedStyleType;

  final List<String> _priceFilters = ['All', 'Budget', 'Mid-range', 'Premium'];
  final List<String> _styleTypes = ['All', 'Casual', 'Formal', 'Semi-formal'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final shopProductsAsync = ref.watch(smartShopProductsProvider);

    // Build current filters
    final filters = ShopFilters(
      priceRange: _selectedPriceFilter,
      category: _selectedCategory,
      styleType: _selectedStyleType == 'All' ? null : _selectedStyleType,
    );

    final filteredProducts = ref.watch(filteredShopProductsProvider(filters));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Shop', style: theme.textTheme.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.go(RoutePaths.profile);
            },
          ),
        ],
      ),
      body: shopProductsAsync.when(
        data: (products) => Column(
          children: [
            // Price filter chips
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _priceFilters.length,
                itemBuilder: (context, index) {
                  final filter = _priceFilters[index];
                  final isSelected = filter == _selectedPriceFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPriceFilter = filter;
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
                            : (isDarkMode
                                ? AppColors.borderLightDark
                                : AppColors.borderLight),
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

            // Style type filter
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _styleTypes.length,
                itemBuilder: (context, index) {
                  final styleType = _styleTypes[index];
                  final isSelected = styleType == (_selectedStyleType ?? 'All');
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(styleType),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStyleType = styleType == 'All' ? null : styleType;
                        });
                      },
                      backgroundColor: theme.cardTheme.color,
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: theme.colorScheme.primary,
                      labelStyle: AppTextStyles.badge.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDarkMode
                                ? AppColors.borderLightDark
                                : AppColors.borderLight),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Products count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    '${filteredProducts.length} Products Available',
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Products grid
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: isDarkMode
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No products found',
                            style: AppTextStyles.h3.copyWith(
                              color: theme.textTheme.headlineSmall?.color,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Try adjusting your filters',
                            style: AppTextStyles.bodyRegular.copyWith(
                              color: isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _ProductCard(product: product);
                      },
                    ),
            ),
          ],
        ),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Loading products...',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: isDarkMode
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load products',
                  style: AppTextStyles.h3.copyWith(
                    color: theme.textTheme.headlineSmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => ref.refresh(smartShopProductsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Product card widget
class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final ShopProduct product;

  Future<void> _openProductUrl(BuildContext context) async {
    // ALWAYS use Amazon search for better compatibility
    // Backend URLs might point to sites with access restrictions (H&M, etc.)
    final searchQuery = Uri.encodeComponent('${product.name} ${product.category}');
    final urlToOpen = 'https://www.amazon.com/s?k=$searchQuery';

    // Show info that we're searching Amazon
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening Amazon search...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final uri = Uri.parse(urlToOpen);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: $e'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final shopService = ref.watch(shopServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? AppColors.shadowMediumDark
                : AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.cardRadius),
              ),
              child: CachedNetworkImage(
                imageUrl: shopService.getProductImageUrl(product.imageId),
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDarkMode
                      ? AppColors.borderLightDark
                      : AppColors.borderLight,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDarkMode
                      ? AppColors.borderLightDark
                      : AppColors.borderLight,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 32,
                      color: isDarkMode
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Product details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product.name,
                  style: AppTextStyles.itemName.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Category
                Text(
                  product.category,
                  style: AppTextStyles.caption.copyWith(
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Price
                Text(
                  product.price,
                  style: AppTextStyles.h3.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Buy Now button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openProductUrl(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
