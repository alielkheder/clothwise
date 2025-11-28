import 'package:clothwise/src/features/home/domain/entities/outfit.dart';
import 'package:clothwise/src/features/home/domain/entities/weather.dart';
import 'package:clothwise/src/features/home/domain/repositories/home_repository.dart';
import 'package:clothwise/src/features/home/data/datasources/home_fake_datasource.dart';

/// Implementation of HomeRepository
/// NOTE: This currently uses fake outfit data for the home screen demo.
/// User's REAL outfit recommendations are saved via OutfitStorageService
/// when they upload photos and get AI recommendations.
/// Access saved outfits using: OutfitStorageService().getLatestOutfit()
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    HomeFakeDataSource? dataSource,
  }) : _dataSource = dataSource ?? HomeFakeDataSource();

  final HomeFakeDataSource _dataSource;
  Weather? _cachedWeather;
  Outfit? _cachedOutfit;

  @override
  Future<Weather> getCurrentWeather() async {
    // Return cached weather if available
    if (_cachedWeather != null) {
      return _cachedWeather!;
    }

    // Fetch and cache weather
    _cachedWeather = await _dataSource.getWeather();
    return _cachedWeather!;
  }

  @override
  Future<Outfit> getTodayOutfit() async {
    // Return cached outfit if available
    if (_cachedOutfit != null) {
      return _cachedOutfit!;
    }

    // Generate new outfit based on weather
    final weather = await getCurrentWeather();
    _cachedOutfit = await _dataSource.generateOutfit(weather);
    return _cachedOutfit!;
  }

  @override
  Future<Outfit> getNewOutfit() async {
    // Clear cache and generate new outfit
    _cachedOutfit = null;
    final weather = await getCurrentWeather();
    _cachedOutfit = await _dataSource.generateOutfit(weather);
    return _cachedOutfit!;
  }

  @override
  Future<List<Outfit>> getSuggestedItems() async {
    return _dataSource.getSuggestedItems();
  }
}
