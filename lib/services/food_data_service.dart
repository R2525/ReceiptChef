// lib/services/food_data_service.dart

class FoodDataService {
  int getShelfLifeDays(String ingredientName) {
    if (ingredientName.contains('고기') || ingredientName.contains('생선')) {
      return 3;
    } else if (ingredientName.contains('야채') || ingredientName.contains('채소')) {
      return 7;
    } else if (ingredientName.contains('과일')) {
      return 5;
    } else if (ingredientName.contains('양파')) {
      return 30;
    }
    return 7; // 기본값
  }
}