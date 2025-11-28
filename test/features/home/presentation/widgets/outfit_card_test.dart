import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clothwise/src/features/home/domain/entities/clothing_item.dart';
import 'package:clothwise/src/features/home/domain/entities/outfit.dart';
import 'package:clothwise/src/features/home/domain/entities/weather.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('Weather and Outfit Display', () {
    late Weather testWeather;
    late Outfit testOutfit;

    setUp(() {
      testWeather = const Weather(
        temperature: 25.0,
        city: 'Test City',
        season: Season.spring,
        condition: WeatherCondition.sunny,
      );

      testOutfit = const Outfit(
        id: 'test-outfit',
        topwear: ClothingItem(
          id: 't1',
          name: 'Test Shirt',
          category: ClothingCategory.topwear,
          color: 'Blue',
          usage: ClothingUsage.casual,
        ),
        bottomwear: ClothingItem(
          id: 'b1',
          name: 'Test Pants',
          category: ClothingCategory.bottomwear,
          color: 'Black',
          usage: ClothingUsage.casual,
        ),
        footwear: ClothingItem(
          id: 'f1',
          name: 'Test Shoes',
          category: ClothingCategory.footwear,
          color: 'White',
          usage: ClothingUsage.casual,
        ),
        harmonyScore: 0.92,
        reasons: [
          OutfitReason(
            type: ReasonType.weather,
            title: 'Weather: 25°C — spring',
            description: 'Perfect for spring weather',
          ),
        ],
      );
    });

    testWidgets('displays temperature correctly', (tester) async {
      // Arrange
      final widget = Material(
        child: Column(
          children: [
            Text(
              '${testWeather.temperature.toInt()}°C',
              style: AppTextStyles.temperature,
            ),
          ],
        ),
      );

      // Act
      await pumpApp(tester, widget);

      // Assert
      expect(find.text('25°C'), findsOneWidget);
    });

    testWidgets('displays city name correctly', (tester) async {
      // Arrange
      final widget = Material(
        child: Column(
          children: [
            Text(
              testWeather.city,
              style: AppTextStyles.location,
            ),
          ],
        ),
      );

      // Act
      await pumpApp(tester, widget);

      // Assert
      expect(find.text('Test City'), findsOneWidget);
    });

    testWidgets('displays harmony score correctly', (tester) async {
      // Arrange
      final widget = Material(
        child: Column(
          children: [
            Text(
              testOutfit.harmonyScore.toStringAsFixed(2),
              style: AppTextStyles.h2,
            ),
          ],
        ),
      );

      // Act
      await pumpApp(tester, widget);

      // Assert
      expect(find.text('0.92'), findsOneWidget);
    });

    testWidgets('displays season badge', (tester) async {
      // Arrange
      final widget = Material(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_sunny, size: 14),
              const SizedBox(width: 4),
              Text(testWeather.season.displayName),
            ],
          ),
        ),
      );

      // Act
      await pumpApp(tester, widget);

      // Assert
      expect(find.text('spring'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('outfit has all required items', (tester) async {
      // Assert
      expect(testOutfit.topwear.name, equals('Test Shirt'));
      expect(testOutfit.bottomwear.name, equals('Test Pants'));
      expect(testOutfit.footwear.name, equals('Test Shoes'));
      expect(testOutfit.allItems.length, greaterThanOrEqualTo(3));
    });

    testWidgets('outfit includes accessory when present', (tester) async {
      // Arrange
      final outfitWithAccessory = Outfit(
        id: 'test-outfit-2',
        topwear: testOutfit.topwear,
        bottomwear: testOutfit.bottomwear,
        footwear: testOutfit.footwear,
        accessory: const ClothingItem(
          id: 'a1',
          name: 'Test Watch',
          category: ClothingCategory.accessory,
          color: 'Silver',
          usage: ClothingUsage.casual,
        ),
        harmonyScore: 0.95,
        reasons: const [],
      );

      // Assert
      expect(outfitWithAccessory.accessory, isNotNull);
      expect(outfitWithAccessory.allItems.length, equals(4));
    });
  });
}
