import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:clothwise/src/features/home/domain/entities/clothing_item.dart';
import 'package:clothwise/src/features/home/domain/entities/outfit.dart';
import 'package:clothwise/src/features/home/domain/entities/weather.dart';
import 'package:clothwise/src/app/theme/app_theme.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';

void main() {
  group('Home Screen Golden Tests', () {
    testGoldens('Home screen - outfit card with weather', (tester) async {
      // Arrange
      const weather = Weather(
        temperature: 33.0,
        city: 'Cairo',
        season: Season.summer,
        condition: WeatherCondition.sunny,
      );

      const outfit = Outfit(
        id: 'test-outfit',
        topwear: const ClothingItem(
          id: 't1',
          name: 'White T-Shirt',
          category: ClothingCategory.topwear,
          color: 'White',
          usage: ClothingUsage.casual,
        ),
        bottomwear: const ClothingItem(
          id: 'b1',
          name: 'Beige Shorts',
          category: ClothingCategory.bottomwear,
          color: 'Beige',
          usage: ClothingUsage.casual,
        ),
        footwear: const ClothingItem(
          id: 'f1',
          name: 'Brown Sandals',
          category: ClothingCategory.footwear,
          color: 'Brown',
          usage: ClothingUsage.casual,
        ),
        harmonyScore: 0.92,
        reasons: const [
          OutfitReason(
            type: ReasonType.weather,
            title: 'Weather: 33°C — summer',
            description: 'Perfect temperature for lightweight',
          ),
          OutfitReason(
            type: ReasonType.color,
            title: 'Color: Complementary',
            description: 'Colors work together',
          ),
          OutfitReason(
            type: ReasonType.usage,
            title: 'Usage: Casual',
            description: 'Comfortable and relaxed',
          ),
        ],
      );

      final widget = MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _OutfitCardDemo(weather: weather, outfit: outfit),
          ),
        ),
      );

      // Act & Assert
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'home_outfit_card_light');
    });
  });
}

/// Demo widget for golden test
class _OutfitCardDemo extends StatelessWidget {
  const _OutfitCardDemo({
    required this.weather,
    required this.outfit,
  });

  final Weather weather;
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Temperature and preview
          Row(
            children: [
              Text(
                '${weather.temperature.toInt()}°C',
                style: AppTextStyles.temperature,
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                height: 80,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    4,
                    (index) => Container(
                      decoration: BoxDecoration(
                        color: index == 2
                            ? AppColors.blueAccent
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Location
          Text(weather.city, style: AppTextStyles.location),

          const SizedBox(height: AppSpacing.sm),

          // Season badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.summerBadgeBg,
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wb_sunny,
                  size: 14,
                  color: AppColors.summerBadgeText,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  weather.season.displayName,
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.summerBadgeText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Harmony indicator
          Center(
            child: Column(
              children: [
                Text(
                  outfit.harmonyScore.toStringAsFixed(2),
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Harmony',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Wear this'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.shuffle, size: 16),
                  label: const Text('Shuffle outfit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
