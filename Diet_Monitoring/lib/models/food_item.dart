import 'package:flutter/material.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.dinner: return 'Dinner';
      case MealType.snack: return 'Snack';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast: return Icons.free_breakfast_rounded;
      case MealType.lunch: return Icons.lunch_dining_rounded;
      case MealType.dinner: return Icons.dinner_dining_rounded;
      case MealType.snack: return Icons.cookie_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MealType.breakfast: return const Color(0xFFFFE66D);
      case MealType.lunch: return const Color(0xFF6C63FF);
      case MealType.dinner: return const Color(0xFF00C896);
      case MealType.snack: return const Color(0xFF00D9FF);
    }
  }
}

class FoodItem {
  final int id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String unit;
  final DateTime loggedAt;
  final MealType mealType;

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingSize = 100.0,
    this.unit = 'g',
    DateTime? loggedAt,
    this.mealType = MealType.snack,
  }) : loggedAt = loggedAt ?? DateTime.now();

  // Get nutrition per gram
  double get caloriesPerGram => servingSize > 0 ? calories / servingSize : 0;
  double get proteinPerGram => servingSize > 0 ? protein / servingSize : 0;
  double get carbsPerGram => servingSize > 0 ? carbs / servingSize : 0;
  double get fatPerGram => servingSize > 0 ? fat / servingSize : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
      'unit': unit,
      'loggedAt': loggedAt.toIso8601String(),
      'mealType': mealType.index,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int,
      name: json['name'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 100.0,
      unit: json['unit'] as String? ?? 'g',
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      mealType: MealType.values[json['mealType'] as int? ?? 3],
    );
  }

  FoodItem copyWith({
    int? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? servingSize,
    String? unit,
    DateTime? loggedAt,
    MealType? mealType,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingSize: servingSize ?? this.servingSize,
      unit: unit ?? this.unit,
      loggedAt: loggedAt ?? this.loggedAt,
      mealType: mealType ?? this.mealType,
    );
  }
}