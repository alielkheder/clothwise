import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothwise/src/app/router.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/app/theme/theme_provider.dart';
import 'package:clothwise/src/features/recommendations/data/recommendation_service.dart';
import 'package:clothwise/src/features/home/data/datasources/outfit_storage_service.dart';

/// Recommendations screen - Shows AI recommendations based on uploaded item
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({
    required this.imagePath,
    super.key,
  });

  final String imagePath;

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  Map<String, List<ProductRecommendation>> _recommendations = {};
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';
  bool _showAllCategories = false;
  String _selectedStyleType = 'All'; // All, Casual, Formal, Semi-formal
  int _currentPage = 0; // Track which page of 3 items we're showing
  static const int _itemsPerPage = 3; // Show 3 items at a time

  // Track selected items for building outfit
  final Set<String> _selectedItems = {}; // Stores product names

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load recommendations from AI backend
      final recommendations = await _recommendationService.getRecommendations(
        imagePath: widget.imagePath,
        numItems: 15,  // Get more items so we can shuffle through them
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ProductRecommendation> _getAllRecommendations() {
    // Return all recommendations from all categories (remove duplicates by name)
    final allProducts = <ProductRecommendation>[];
    final seenNames = <String>{};

    for (final products in _recommendations.values) {
      for (final product in products) {
        if (!seenNames.contains(product.name)) {
          seenNames.add(product.name);
          allProducts.add(product);
        }
      }
    }
    return allProducts;
  }

  List<ProductRecommendation> _getFilteredRecommendations() {
    // Start with all or category-filtered products
    List<ProductRecommendation> filtered;

    if (_selectedCategory == 'All') {
      filtered = _getAllRecommendations();
    } else {
      final categoryFiltered = <ProductRecommendation>[];
      final seenNames = <String>{};

      for (final products in _recommendations.values) {
        for (final product in products) {
          if (product.category == _selectedCategory && !seenNames.contains(product.name)) {
            seenNames.add(product.name);
            categoryFiltered.add(product);
          }
        }
      }
      filtered = categoryFiltered;
    }

    // Apply style type filter
    if (_selectedStyleType != 'All') {
      // Map "Formal" to "uniform" and "Semi-formal" to "semi_uniform"
      final styleTypeFilter = _selectedStyleType == 'Formal'
          ? 'uniform'
          : _selectedStyleType == 'Semi-formal'
              ? 'semi_uniform'
              : 'casual';

      filtered = filtered.where((product) => product.styleType == styleTypeFilter).toList();
    }

    return filtered;
  }

  List<ProductRecommendation> _getPagedRecommendations() {
    final allFiltered = _getFilteredRecommendations();

    if (allFiltered.isEmpty) return [];

    // Calculate start and end indices for current page
    final startIndex = (_currentPage * _itemsPerPage) % allFiltered.length;
    final endIndex = startIndex + _itemsPerPage;

    // Handle wrapping if we go past the end
    if (endIndex <= allFiltered.length) {
      return allFiltered.sublist(startIndex, endIndex);
    } else {
      // Wrap around to the beginning
      final remaining = endIndex - allFiltered.length;
      return [...allFiltered.sublist(startIndex), ...allFiltered.sublist(0, remaining)];
    }
  }

  void _shuffleRecommendations() {
    setState(() {
      _currentPage++;
    });
  }

  void _toggleItemSelection(ProductRecommendation product) {
    setState(() {
      if (_selectedItems.contains(product.name)) {
        _selectedItems.remove(product.name);
      } else {
        _selectedItems.add(product.name);
      }
    });
  }

  Future<void> _saveSelectedOutfit() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    // Get the full product data for selected items
    final selectedProducts = <ProductRecommendation>[];
    for (final products in _recommendations.values) {
      for (final product in products) {
        if (_selectedItems.contains(product.name)) {
          selectedProducts.add(product);
        }
      }
    }

    // Save to storage
    final storageService = OutfitStorageService();
    await storageService.saveOutfit({
      'type': 'user_selected_outfit',
      'imagePath': widget.imagePath,
      'selectedItems': selectedProducts
          .map((p) => {
                'name': p.name,
                'category': p.category,
                'price': p.price,
                'imageId': p.imageId,
              })
          .toList(),
      'description': 'My selected outfit (${selectedProducts.length} items)',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${_selectedItems.length} items to your outfit!')),
      );
    }
  }

  List<String> _getAvailableCategories() {
    final categories = <String>{'All'};
    for (final products in _recommendations.values) {
      for (final product in products) {
        categories.add(product.category);
      }
    }
    return categories.toList()..sort();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.wardrobe),
        ),
        title: Text('Recommendations', style: theme.textTheme.headlineLarge),
        actions: [
          if (_selectedItems.isNotEmpty)
            TextButton.icon(
              onPressed: _saveSelectedOutfit,
              icon: const Icon(Icons.check_circle),
              label: Text('Save (${_selectedItems.length})'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () => context.go(RoutePaths.home),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Getting AI recommendations...',
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
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
                          'Failed to load recommendations',
                          style: AppTextStyles.h3.copyWith(
                            color: theme.textTheme.headlineSmall?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: _loadRecommendations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Uploaded Item Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uploaded Item',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
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
                        child: widget.imagePath.startsWith('http')
                            ? Image.network(
                                widget.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Style Type Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Style Type',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: ['All', 'Casual', 'Formal', 'Semi-formal'].map((styleType) {
                      final isSelected = _selectedStyleType == styleType;
                      return FilterChip(
                        label: Text(styleType),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStyleType = styleType;
                            _currentPage = 0; // Reset to first page when filter changes
                          });
                        },
                        backgroundColor: theme.cardTheme.color,
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: AppTextStyles.badge.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyLarge?.color,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Category Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Category',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      // Show first 3 categories
                      ..._getAvailableCategories().take(_showAllCategories ? _getAvailableCategories().length : 3).map((category) {
                        final isSelected = _selectedCategory == category;
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                              _currentPage = 0; // Reset to first page when filter changes
                            });
                          },
                          backgroundColor: theme.cardTheme.color,
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          labelStyle: AppTextStyles.badge.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyLarge?.color,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                          ),
                        );
                      }),
                      // Show "More" button if there are more than 3 categories
                      if (_getAvailableCategories().length > 3)
                        FilterChip(
                          label: Text(_showAllCategories ? 'Less' : 'More'),
                          selected: false,
                          onSelected: (selected) {
                            setState(() {
                              _showAllCategories = !_showAllCategories;
                            });
                          },
                          backgroundColor: theme.cardTheme.color,
                          labelStyle: AppTextStyles.badge.copyWith(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          side: BorderSide(
                            color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                          ),
                          avatar: Icon(
                            _showAllCategories ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Your Personalized Recommendations Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Personalized Recommendations',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Builder(
                    builder: (context) {
                      final pagedProducts = _getPagedRecommendations();

                      if (pagedProducts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              'No recommendations available',
                              style: AppTextStyles.bodyRegular.copyWith(
                                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pagedProducts.length,
                        itemBuilder: (context, index) {
                          final product = pagedProducts[index];
                          return _RecommendationCard(
                            product: product,
                            recommendationService: _recommendationService,
                            isSelected: _selectedItems.contains(product.name),
                            onToggle: () => _toggleItemSelection(product),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _shuffleRecommendations, // Cycle through next 3 recommendations
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.shuffle, color: theme.colorScheme.onPrimary),
      ),
    );
  }
}

/// Recommendation card widget
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.product,
    required this.recommendationService,
    required this.isSelected,
    required this.onToggle,
  });

  final ProductRecommendation product;
  final RecommendationService recommendationService;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 3,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? AppColors.shadowMediumDark : AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.cardRadius),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: recommendationService.getProductImageUrl(product.imageId),
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

                // Details
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.h3.copyWith(
                          color: theme.textTheme.headlineSmall?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(product.category),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              product.category,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
            // Selection indicator overlay
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'casual':
        return Colors.blue;
      case 'formal':
        return Colors.purple;
      case 'smart casual':
        return Colors.orange;
      default:
        return AppColors.primaryBrown;
    }
  }
}
