import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/recipe.dart';

class SpoonacularService {
  static const String _baseUrl = 'https://api.spoonacular.com';

  Future<List<IngredientSearchResult>> searchIngredients(String query, String apiKey) async {
    if (apiKey.isEmpty) {
      throw Exception('API key not set');
    }

    try {
      final uri = Uri.parse(
          '$_baseUrl/food/ingredients/search?query=$query&number=10&apiKey=$apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 402) {
        throw Exception('DAILY_API_QUOTA_REACHED');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to search ingredients: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>?;

      if (results == null) {
        return [];
      }

      return results.map((item) => IngredientSearchResult(
        id: item['id'] as int,
        name: item['name'] as String,
        image: item['image'] as String?,
      )).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<FoodItem> getIngredientNutrition(int ingredientId, String apiKey) async {
    if (apiKey.isEmpty) {
      throw Exception('API key not set');
    }

    try {
      final uri = Uri.parse(
          '$_baseUrl/food/ingredients/$ingredientId/information?amount=1&unit=piece&apiKey=$apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 402) {
        throw Exception('DAILY_API_QUOTA_REACHED');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to get nutrition: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      double calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;

      // Handle nutrition - can be { nutrients: [...] } or direct list
      final nutritionData = data['nutrition'];
      if (nutritionData is Map) {
        // API returns { nutrients: [...] }
        final nutrients = nutritionData['nutrients'];
        if (nutrients is List) {
          for (final nutrient in nutrients) {
            if (nutrient is! Map) continue;
            final name = (nutrient['name'] as String?)?.toLowerCase() ?? '';
            final amount = (nutrient['amount'] as num?)?.toDouble() ?? 0;
            final unit = (nutrient['unit'] as String?) ?? '';

            if (name.contains('calor') || name.contains('energy')) {
              calories = amount;
            } else if (name.contains('protein')) {
              protein = amount;
            } else if (name.contains('carb') || name.contains('carbohydrate')) {
              carbs = amount;
            } else if (name.contains('fat')) {
              fat = amount;
            }
          }
        }
      } else if (nutritionData is List) {
        // Fallback: direct list
        for (final nutrient in nutritionData) {
          if (nutrient is! Map) continue;
          final name = (nutrient['name'] as String?)?.toLowerCase() ?? '';
          final amount = (nutrient['amount'] as num?)?.toDouble() ?? 0;

          if (name.contains('calor') || name.contains('energy')) {
            calories = amount;
          } else if (name.contains('protein')) {
            protein = amount;
          } else if (name.contains('carb') || name.contains('carbohydrate')) {
            carbs = amount;
          } else if (name.contains('fat')) {
            fat = amount;
          }
        }
      }

      // Get serving info
      final servings = data['servings'] as Map? ?? {};
      final servingSize = servings['size'] as num? ?? 1;

      return FoodItem(
        id: ingredientId,
        name: data['name'] as String? ?? 'Unknown',
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingSize: servingSize.toDouble(),
        unit: 'g',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Recipe>> searchRecipes(String query, String apiKey) async {
    if (apiKey.isEmpty) {
      throw Exception('API key not set');
    }

    try {
      final uri = Uri.parse(
          '$_baseUrl/recipes/complexSearch?query=$query&addRecipeNutrition=true&number=10&apiKey=$apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 402) {
        throw Exception('DAILY_API_QUOTA_REACHED');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to search recipes: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      
      if (data is! Map<String, dynamic>) {
        return [];
      }
      
      final results = data['results'];
      
      if (results == null) {
        return [];
      }
      
      if (results is! List<dynamic>) {
        return [];
      }

      return results.map((item) {
        if (item is! Map<String, dynamic>) {
          return Recipe(
            id: 0,
            title: 'Unknown',
            imageUrl: null,
            readyInMinutes: 0,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
          );
        }
        
        final nutrition = item['nutrition'];

        double calories = 0;
        double protein = 0;
        double carbs = 0;
        double fat = 0;

        // Spoonacular returns nutrition as { nutrients: [...] }
        if (nutrition is Map) {
          final nutrients = nutrition['nutrients'];
          if (nutrients is List) {
            for (final n in nutrients) {
              if (n is! Map) continue;
              final name = (n['name'] as String?)?.toLowerCase() ?? '';
              final amount = (n['amount'] as num?)?.toDouble() ?? 0;

              if (name.contains('calor') || name.contains('energy')) {
                calories = amount;
              } else if (name.contains('protein')) {
                protein = amount;
              } else if (name.contains('carb') || name.contains('carbohydrate')) {
                carbs = amount;
              } else if (name.contains('fat')) {
                fat = amount;
              }
            }
          }
        }

        // Fallback: try parsing as direct list
        if (calories == 0 && protein == 0 && nutrition is List) {
          for (final n in nutrition) {
            if (n is! Map) continue;
            final name = (n['name'] as String?)?.toLowerCase() ?? '';
            final amount = (n['amount'] as num?)?.toDouble() ?? 0;

            if (name.contains('calor') || name.contains('energy')) {
              calories = amount;
            } else if (name.contains('protein')) {
              protein = amount;
            } else if (name.contains('carb') || name.contains('carbohydrate')) {
              carbs = amount;
            } else if (name.contains('fat')) {
              fat = amount;
            }
          }
        }

        return Recipe(
          id: item['id'] as int,
          title: item['title'] as String? ?? 'Unknown',
          imageUrl: item['image'] as String?,
          readyInMinutes: item['readyInMinutes'] as int? ?? 0,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Recipe> getRecipeDetails(int recipeId, String apiKey) async {
    if (apiKey.isEmpty) {
      throw Exception('API key not set');
    }

    try {
      final uri = Uri.parse(
          '$_baseUrl/recipes/$recipeId/information?includeNutrition=true&apiKey=$apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 402) {
        throw Exception('DAILY_API_QUOTA_REACHED');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to get recipe details: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      final extendedIngredients = data['extendedIngredients'] as List<dynamic>? ?? [];
      final ingredients = extendedIngredients.map((item) => RecipeIngredient(
        name: item['name'] as String? ?? '',
        amount: item['amount']?.toString() ?? '',
        original: item['original'] as String?,
      )).toList();

      final analyzedInstructions = data['analyzedInstructions'] as List<dynamic>? ?? [];
      final steps = <RecipeStep>[];

      if (analyzedInstructions.isNotEmpty) {
        final stepsList = analyzedInstructions[0]['steps'] as List<dynamic>? ?? [];
        for (final step in stepsList) {
          steps.add(RecipeStep(
            number: step['number'] as int? ?? 0,
            step: step['step'] as String? ?? '',
          ));
        }
      }

      final nutritionList = data['nutrition'];

      double calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;

      // Spoonacular returns nutrition as { nutrients: [...] } for recipe details
      if (nutritionList is Map) {
        final nutrients = nutritionList['nutrients'];
        if (nutrients is List) {
          for (final n in nutrients) {
            if (n is! Map) continue;
            final name = (n['name'] as String?)?.toLowerCase() ?? '';
            final amount = (n['amount'] as num?)?.toDouble() ?? 0;

            if (name.contains('calor') || name.contains('energy')) {
              calories = amount;
            } else if (name.contains('protein')) {
              protein = amount;
            } else if (name.contains('carb') || name.contains('carbohydrate')) {
              carbs = amount;
            } else if (name.contains('fat')) {
              fat = amount;
            }
          }
        }
      }

      return Recipe(
        id: data['id'] as int,
        title: data['title'] as String? ?? 'Unknown',
        imageUrl: data['image'] as String?,
        readyInMinutes: data['readyInMinutes'] as int? ?? 0,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        ingredients: ingredients,
        steps: steps,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class IngredientSearchResult {
  final int id;
  final String name;
  final String? image;

  IngredientSearchResult({
    required this.id,
    required this.name,
    this.image,
  });
}