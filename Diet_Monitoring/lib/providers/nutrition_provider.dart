import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';

class NutritionProvider extends ChangeNotifier {
  List<FoodItem> _foodLog = [];
  int _calorieGoal = 2000;
  bool _isLoading = false;

  List<FoodItem> get foodLog => _foodLog;
  int get calorieGoal => _calorieGoal;
  bool get isLoading => _isLoading;

  double get totalCalories => _foodLog.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => _foodLog.fold(0, (sum, item) => sum + item.protein);
  double get totalCarbs => _foodLog.fold(0, (sum, item) => sum + item.carbs);
  double get totalFat => _foodLog.fold(0, (sum, item) => sum + item.fat);

  int get workoutCount => 0;
  int _hydrationGlasses = 0;

  int get hydrationGlasses => _hydrationGlasses;

  void setCalorieGoal(int goal) {
    _calorieGoal = goal;
    _saveSettings();
    notifyListeners();
  }

  void incrementHydration() {
    _hydrationGlasses++;
    notifyListeners();
  }

  void decrementHydration() {
    if (_hydrationGlasses > 0) {
      _hydrationGlasses--;
      notifyListeners();
    }
  }

  Future<void> loadTodayLog() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getDateKey(DateTime.now());
      final key = 'food_log_$today';
      final jsonString = prefs.getString(key);

      _calorieGoal = prefs.getInt('calorie_goal') ?? 2000;
      _hydrationGlasses = prefs.getInt('hydration_$today') ?? 0;

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _foodLog = jsonList
            .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _foodLog = [];
      }
    } catch (e) {
      _foodLog = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFood(FoodItem food) async {
    _foodLog.add(food);
    await _saveFoodLog();
    notifyListeners();
  }

  Future<void> removeFood(int index) async {
    if (index >= 0 && index < _foodLog.length) {
      _foodLog.removeAt(index);
      await _saveFoodLog();
      notifyListeners();
    }
  }

  Future<void> _saveFoodLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getDateKey(DateTime.now());
      final key = 'food_log_$today';
      final jsonString = json.encode(_foodLog.map((e) => e.toJson()).toList());
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error saving food log: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('calorie_goal', _calorieGoal);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> saveHydration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getDateKey(DateTime.now());
      await prefs.setInt('hydration_$today', _hydrationGlasses);
    } catch (e) {
      debugPrint('Error saving hydration: $e');
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}