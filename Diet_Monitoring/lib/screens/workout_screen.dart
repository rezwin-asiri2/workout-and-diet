import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../config/keys/api_keys.dart';
import '../config/theme.dart';
import '../services/weather_service.dart';
import '../models/workout_log.dart';
import '../providers/workout_provider.dart';
import '../widgets/weather_advisory_card.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  WeatherData? _weather;
  bool _isLoadingWeather = false;
  String? _weatherError;

  @override
  void initState() { super.initState(); _loadWeather(); }

  Future<void> _loadWeather() async {
    setState(() { _isLoadingWeather = true; _weatherError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = ApiKeys.openWeather;
      final city = prefs.getString('city') ?? '';
      if (city.isEmpty) { setState(() => _isLoadingWeather = false); return; }
      final weatherService = WeatherService();
      final weather = await weatherService.getWeather(city, apiKey);
      setState(() { _weather = weather; _isLoadingWeather = false; });
    } catch (e) { setState(() { _weatherError = e.toString(); _isLoadingWeather = false; }); }
  }

  void _showAddWorkoutDialog() {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    WorkoutType selectedType = WorkoutType.cardio;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: AppSpacing.xl),
                Row(children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.fitness_center_rounded, color: AppTheme.primary, size: 24)),
                  const SizedBox(width: AppSpacing.md),
                  const Text('Log Workout', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                const Text('Workout Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: WorkoutType.values.map((type) {
                  final isSelected = selectedType == type;
                  final color = _getTypeColor(type);
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedType = type),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_getTypeIcon(type), color: isSelected ? color : AppTheme.textTertiary, size: 18),
                        const SizedBox(width: 8),
                        Text(type.displayName, style: TextStyle(color: isSelected ? color : AppTheme.textTertiary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                      ]),
                    ),
                  );
                }).toList()),
                const SizedBox(height: AppSpacing.lg),
                const Text('Popular Exercises', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: _getExerciseList(selectedType).map((exercise) {
                  final isSelected = nameController.text == exercise;
                  return GestureDetector(
                    onTap: () => setDialogState(() => nameController.text = exercise),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.textTertiary.withValues(alpha: 0.3))),
                      child: Text(exercise, style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textSecondary, fontSize: 12)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: AppSpacing.lg),
                TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Exercise name', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), filled: true, fillColor: AppTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none), prefixIcon: Icon(_getTypeIcon(selectedType), color: AppTheme.textTertiary))),
                const SizedBox(height: AppSpacing.lg),
                TextField(controller: durationController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Duration (minutes)', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), filled: true, fillColor: AppTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.timer_rounded, color: AppTheme.textTertiary))),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(width: double.infinity, child: GestureDetector(
                  onTap: () {
                    final name = nameController.text.trim();
                    final duration = int.tryParse(durationController.text) ?? 30;
                    if (name.isEmpty) return;
                    context.read<WorkoutProvider>().addWorkout(WorkoutLog(id: DateTime.now().millisecondsSinceEpoch.toString(), exerciseName: name, durationMinutes: duration, type: selectedType));
                    Navigator.pop(context);
                  },
                  child: Container(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppTheme.buttonShadow), child: const Center(child: Text('Add Workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)))),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getExerciseList(WorkoutType type) {
    switch (type) {
      case WorkoutType.cardio: return ['Running', 'Jogging', 'Walking', 'Cycling', 'Swimming', 'Jump Rope', 'Rowing', 'Stair Climber', 'Elliptical', 'Dancing', 'Hiking', 'Boxing'];
      case WorkoutType.strength: return ['Weight Training', 'Push-ups', 'Pull-ups', 'Squats', 'Deadlifts', 'Bench Press', 'Bicep Curls', 'Tricep Dips', 'Shoulder Press', 'Lunges', 'Plank', 'Burpees'];
      case WorkoutType.hiit: return ['HIIT Workout', 'Tabata', 'Circuit Training', 'Sprint Intervals', 'Mountain Climbers', 'Burpee Challenge', 'Kettlebell Swing', 'Battle Ropes', 'Box Jumps', 'Squat Jumps', 'Plank Jacks', 'Bear Crawls'];
      case WorkoutType.flexibility: return ['Stretching', 'Yoga', 'Pilates', 'Foam Rolling', 'Tai Chi', 'Dynamic Stretching', 'Static Stretching', 'Hip Flexor Stretch', 'Hamstring Stretch', 'Shoulder Stretch', 'Neck Release', 'Back Flexibility'];
    }
  }

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Start Workout', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        _buildSuggestionCard('🏃 Cardio', 'Burn calories, improve heart health', AppTheme.caloriesColor, Icons.directions_run_rounded, WorkoutType.cardio),
        const SizedBox(height: AppSpacing.sm),
        _buildSuggestionCard('💪 Strength', 'Build muscle, increase metabolism', AppTheme.primary, Icons.fitness_center_rounded, WorkoutType.strength),
        const SizedBox(height: AppSpacing.sm),
        _buildSuggestionCard('⚡ HIIT', 'Maximize fat burn in less time', AppTheme.warning, Icons.flash_on_rounded, WorkoutType.hiit),
        const SizedBox(height: AppSpacing.sm),
        _buildSuggestionCard('🧘 Flexibility', 'Improve mobility, prevent injury', AppTheme.secondary, Icons.self_improvement_rounded, WorkoutType.flexibility),
      ]),
    );
  }

  Widget _buildSuggestionCard(String title, String subtitle, Color color, IconData icon, WorkoutType type) {
    return GestureDetector(
      onTap: () { nameController.text = _getExerciseList(type)[0]; _showAddWorkoutDialog(); },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)), Text(subtitle, style: TextStyle(color: AppTheme.textTertiary, fontSize: 12))])),
          Icon(Icons.add_circle_rounded, color: color, size: 22),
        ]),
      ),
    );
  }

  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ShaderMask(shaderCallback: (b) => AppTheme.primaryGradient.createShader(b), child: const Text('Workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28))),
                  const SizedBox(height: 4),
                  Consumer<WorkoutProvider>(builder: (context, workout, _) => Text('${workout.todayWorkoutCount} workouts today', style: TextStyle(color: AppTheme.textTertiary, fontSize: 14))),
                ]),
                GestureDetector(
                  onTap: _showAddWorkoutDialog,
                  child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.buttonShadow), child: const Icon(Icons.add_rounded, color: Colors.white, size: 22)),
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              WeatherAdvisoryCard(weather: _weather, isLoading: _isLoadingWeather, errorMessage: _weatherError, onRetry: _loadWeather),
              const SizedBox(height: AppSpacing.lg),
              _buildSuggestions(),
              const SizedBox(height: AppSpacing.lg),
            ]))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: _buildSummary())),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Today's Workouts", style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)), Consumer<WorkoutProvider>(builder: (context, workout, _) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: Text('${workout.workoutLog.length}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))))]))),
            _buildWorkoutList(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Consumer<WorkoutProvider>(builder: (context, workout, _) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppTheme.cardShadow),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('${workout.todayWorkoutCount}', 'Workouts', AppTheme.primary),
            Container(height: 40, width: 1, color: AppTheme.textTertiary.withValues(alpha: 0.2)),
            _statItem('${workout.totalCaloriesBurned.toInt()}', 'Calories', AppTheme.caloriesColor),
            Container(height: 40, width: 1, color: AppTheme.textTertiary.withValues(alpha: 0.2)),
            _statItem('${workout.workoutLog.fold(0, (sum, w) => sum + w.durationMinutes)}', 'Minutes', AppTheme.secondary),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _buildWeekIndicator(),
        ]),
      );
    });
  }

  Widget _buildWeekIndicator() {
    final now = DateTime.now();
    final currentDay = now.weekday;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (index) {
      final dayIndex = index + 1;
      final isToday = dayIndex == currentDay;
      final isPast = dayIndex < currentDay;
      return Container(width: 36, height: 36, decoration: BoxDecoration(color: isToday ? AppTheme.primary : isPast ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.surfaceLight, borderRadius: BorderRadius.circular(10), border: isToday ? null : Border.all(color: isPast ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.textTertiary.withValues(alpha: 0.2))), child: Center(child: isPast ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][index], style: TextStyle(color: isToday ? Colors.white : AppTheme.textTertiary, fontSize: 12))));
    }));
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(children: [Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label, style: TextStyle(color: AppTheme.textTertiary, fontSize: 12))]);
  }

  Widget _buildWorkoutList() {
    return Consumer<WorkoutProvider>(builder: (context, workout, _) {
      if (workout.workoutLog.isEmpty) return SliverFillRemaining(hasScrollBody: false, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle), child: Icon(Icons.fitness_center_rounded, color: AppTheme.textTertiary.withValues(alpha: 0.5), size: 40)), const SizedBox(height: AppSpacing.lg), const Text('No workouts logged yet', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)), const SizedBox(height: AppSpacing.sm), Text('Tap + to log your first workout', style: TextStyle(color: AppTheme.textTertiary, fontSize: 14))])));
      return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
        final w = workout.workoutLog[index];
        return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm), child: Dismissible(key: Key('workout_${w.id}'), direction: DismissDirection.endToStart, background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: AppSpacing.lg), decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.lg)), child: const Icon(Icons.delete_rounded, color: AppTheme.error)), onDismissed: (_) => workout.removeWorkout(index), child: Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg)), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _getTypeColor(w.type).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)), child: Icon(_getTypeIcon(w.type), color: _getTypeColor(w.type), size: 22)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(w.exerciseName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 4), Row(children: [Icon(Icons.timer_outlined, color: AppTheme.textTertiary, size: 14), const SizedBox(width: 4), Text('${w.durationMinutes} min', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)), const SizedBox(width: AppSpacing.md), Icon(Icons.local_fire_department_outlined, color: AppTheme.caloriesColor, size: 14), const SizedBox(width: 4), Text('${w.caloriesBurned.toInt()} kcal', style: TextStyle(color: AppTheme.caloriesColor, fontSize: 12))])])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _getTypeColor(w.type).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Text(w.type.displayName, style: TextStyle(color: _getTypeColor(w.type), fontSize: 11, fontWeight: FontWeight.w500)))]))));
      }, childCount: workout.workoutLog.length));
    });
  }

  Color _getTypeColor(WorkoutType type) { switch (type) { case WorkoutType.cardio: return AppTheme.caloriesColor; case WorkoutType.strength: return AppTheme.primary; case WorkoutType.hiit: return AppTheme.warning; case WorkoutType.flexibility: return AppTheme.secondary; } }
  IconData _getTypeIcon(WorkoutType type) { switch (type) { case WorkoutType.cardio: return Icons.directions_run_rounded; case WorkoutType.strength: return Icons.fitness_center_rounded; case WorkoutType.hiit: return Icons.flash_on_rounded; case WorkoutType.flexibility: return Icons.self_improvement_rounded; } }
}