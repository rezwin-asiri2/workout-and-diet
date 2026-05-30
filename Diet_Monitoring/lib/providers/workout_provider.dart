import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_log.dart';

class WorkoutProvider extends ChangeNotifier {
  List<WorkoutLog> _workoutLog = [];
  bool _isLoading = false;

  List<WorkoutLog> get workoutLog => _workoutLog;
  bool get isLoading => _isLoading;

  double get totalCaloriesBurned =>
      _workoutLog.fold(0, (sum, workout) => sum + workout.caloriesBurned);

  int get todayWorkoutCount => _workoutLog.length;

  Future<void> loadTodayLog() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getDateKey(DateTime.now());
      final key = 'workout_log_$today';
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _workoutLog = jsonList
            .map((item) => WorkoutLog.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _workoutLog = [];
      }
    } catch (e) {
      _workoutLog = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWorkout(WorkoutLog workout) async {
    _workoutLog.add(workout);
    await _saveWorkoutLog();
    notifyListeners();
  }

  Future<void> removeWorkout(int index) async {
    if (index >= 0 && index < _workoutLog.length) {
      _workoutLog.removeAt(index);
      await _saveWorkoutLog();
      notifyListeners();
    }
  }

  Future<void> _saveWorkoutLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getDateKey(DateTime.now());
      final key = 'workout_log_$today';
      final jsonString = json.encode(_workoutLog.map((e) => e.toJson()).toList());
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error saving workout log: $e');
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}