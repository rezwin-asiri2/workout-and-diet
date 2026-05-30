enum WorkoutType {
  cardio,
  strength,
  hiit,
  flexibility;

  String get displayName {
    switch (this) {
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.flexibility:
        return 'Flexibility';
    }
  }

  double get caloriesPerMinute {
    switch (this) {
      case WorkoutType.cardio:
        return 10.0;
      case WorkoutType.strength:
        return 7.0;
      case WorkoutType.hiit:
        return 12.0;
      case WorkoutType.flexibility:
        return 4.0;
    }
  }

  static WorkoutType fromString(String value) {
    return WorkoutType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkoutType.cardio,
    );
  }
}

class WorkoutLog {
  final String id;
  final String exerciseName;
  final int durationMinutes;
  final WorkoutType type;
  final double caloriesBurned;
  final DateTime loggedAt;

  WorkoutLog({
    required this.id,
    required this.exerciseName,
    required this.durationMinutes,
    required this.type,
    double? caloriesBurned,
    DateTime? loggedAt,
  })  : caloriesBurned = caloriesBurned ?? (type.caloriesPerMinute * durationMinutes),
        loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'durationMinutes': durationMinutes,
      'type': type.name,
      'caloriesBurned': caloriesBurned,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as String,
      exerciseName: json['exerciseName'] as String,
      durationMinutes: json['durationMinutes'] as int,
      type: WorkoutType.fromString(json['type'] as String),
      caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );
  }
}