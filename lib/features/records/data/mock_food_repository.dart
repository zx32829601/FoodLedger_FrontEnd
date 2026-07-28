import '../domain/models/food.dart';
import '../domain/repositories/food_repository.dart';
import 'mock_foods.dart';

class MockFoodRepository implements FoodRepository {
  MockFoodRepository({List<Food>? foods})
    : _foods = List.of(foods ?? mockFoods);

  final List<Food> _foods;

  @override
  Future<List<Food>> searchFoods({
    required String query,
    required String langCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) return List.unmodifiable(_foods);

    return _foods
        .where(
          (food) =>
              food.name.toLowerCase().contains(normalizedQuery) ||
              food.code.toLowerCase().contains(normalizedQuery) ||
              food.description.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }
}
