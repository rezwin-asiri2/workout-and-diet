class Recipe {
  final int id;
  final String title;
  final String? imageUrl;
  final int readyInMinutes;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  Recipe({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.readyInMinutes,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.ingredients = const [],
    this.steps = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'readyInMinutes': readyInMinutes,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps.map((e) => e.toJson()).toList(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      readyInMinutes: json['readyInMinutes'] as int,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RecipeIngredient {
  final String name;
  final String amount;
  final String? original;

  RecipeIngredient({
    required this.name,
    required this.amount,
    this.original,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'original': original,
    };
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      original: json['original'] as String?,
    );
  }
}

class RecipeStep {
  final int number;
  final String step;

  RecipeStep({
    required this.number,
    required this.step,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'step': step,
    };
  }

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      number: json['number'] as int,
      step: json['step'] as String,
    );
  }
}