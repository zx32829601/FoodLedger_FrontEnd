import '../domain/models/food.dart';
import '../domain/repositories/food_repository.dart';
import 'mock_foods.dart';

class MockFoodRepository implements FoodRepository {
  MockFoodRepository({List<Food>? foods})
    : _foods = List.of(foods ?? mockFoods);

  final List<Food> _foods;

  @override
  Future<FoodSearchResult> searchFoods({
    required String query,
    required String langCode,
    required int page,
    required int pageSize,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final normalizedQuery = query.trim().toLowerCase();

    final matches = normalizedQuery.isEmpty
        ? _foods
        : _foods
              .where(
                (food) =>
                    food.name.toLowerCase().contains(normalizedQuery) ||
                    food.code.toLowerCase().contains(normalizedQuery) ||
                    food.description.toLowerCase().contains(normalizedQuery),
              )
              .toList(growable: false);
    final start = (page - 1) * pageSize;
    final paged = start >= matches.length
        ? <Food>[]
        : matches.skip(start).take(pageSize).toList();
    return FoodSearchResult(
      items: paged
          .map(
            (food) => FoodSearchItem(
              id: food.id,
              code: food.code,
              name: food.name,
              langCode: food.langCode ?? langCode,
              englishName: food.englishName,
              caloriesPer100Grams: food.nutrientPer100Grams('Calories')?.amount,
            ),
          )
          .toList(),
      page: page,
      pageSize: pageSize,
      totalCount: matches.length,
    );
  }

  @override
  Future<Food> getFoodDetail({
    required int foodId,
    required String langCode,
  }) async => _foods.firstWhere((food) => food.id == foodId);
}
