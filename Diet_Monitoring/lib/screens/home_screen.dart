import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../config/keys/api_keys.dart';
import '../config/theme.dart';
import '../services/weather_service.dart';
import '../providers/nutrition_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/weather_advisory_card.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  WeatherData? _weather;
  bool _isLoadingWeather = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _slideController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: AppAnimations.defaultCurve),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: AppAnimations.smoothCurve));
    
    _fadeController.forward();
    _slideController.forward();
    _loadWeather();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = ApiKeys.openWeather;
      final city = prefs.getString('city') ?? '';

      if (city.isEmpty) {
        setState(() {
          _isLoadingWeather = false;
        });
        return;
      }

      final weatherService = WeatherService();
      final weather = await weatherService.getWeather(city, apiKey);

      setState(() {
        _weather = weather;
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _weatherError = e.toString();
        _isLoadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadWeather,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildCalorieCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildWeeklyProgress(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickStats(),
                  const SizedBox(height: AppSpacing.lg),
                  WeatherAdvisoryCard(
                    weather: _weather,
                    isLoading: _isLoadingWeather,
                    errorMessage: _weatherError,
                    onRetry: _loadWeather,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickActions(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildHydration(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'VitalTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.buttonShadow,
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildCalorieCard() {
    return Consumer<NutritionProvider>(
      builder: (context, nutrition, _) {
        final progress = (nutrition.totalCalories / nutrition.calorieGoal).clamp(0.0, 1.0);
        final int remaining = (nutrition.calorieGoal - nutrition.totalCalories).clamp(0, nutrition.calorieGoal).toInt();
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: AppDurations.slow,
          curve: AppAnimations.smoothCurve,
          builder: (context, value, child) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surface,
                    AppTheme.surfaceLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(
                  color: AppTheme.caloriesColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.caloriesColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_fire_department, color: AppTheme.caloriesColor, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Text(
                            'Calories',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${nutrition.calorieGoal} kcal',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: value),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, animValue, _) {
                            return CircularProgressIndicator(
                              value: animValue,
                              strokeWidth: 12,
                              backgroundColor: AppTheme.textTertiary.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.caloriesColor),
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                      ),
                      Column(
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: remaining),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, _) {
                              return Text(
                                '$value',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          Text(
                            'remaining',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroStat('Protein', '${nutrition.totalProtein.toInt()}g', AppTheme.proteinColor),
                        _buildMacroDivider(),
                        _buildMacroStat('Carbs', '${nutrition.totalCarbs.toInt()}g', AppTheme.carbsColor),
                        _buildMacroDivider(),
                        _buildMacroStat('Fat', '${nutrition.totalFat.toInt()}g', AppTheme.fatColor),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMacroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppTheme.textTertiary.withValues(alpha: 0.2),
    );
  }

  Widget _buildWeeklyProgress() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Goal',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Consumer<NutritionProvider>(
                builder: (context, nutrition, _) {
                  final weeklyProgress = (nutrition.totalCalories / (nutrition.calorieGoal * 7) * 100).clamp(0, 100);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${weeklyProgress.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildWeekDayIndicators(),
        ],
      ),
    );
  }

  Widget _buildWeekDayIndicators() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final currentDay = now.weekday;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isToday = dayIndex == currentDay;
        final isPast = dayIndex < currentDay;
        
        return AnimatedContainer(
          duration: AppDurations.fast,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isToday 
                      ? AppTheme.primary
                      : isPast 
                          ? AppTheme.accent.withValues(alpha: 0.3)
                          : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday 
                      ? null 
                      : Border.all(
                          color: isPast 
                              ? AppTheme.accent.withValues(alpha: 0.3)
                              : AppTheme.textTertiary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                ),
                child: Center(
                  child: isPast 
                      ? const Icon(Icons.check_rounded, color: AppTheme.accent, size: 18)
                      : Text(
                          days[index],
                          style: TextStyle(
                            color: isToday ? Colors.white : AppTheme.textTertiary,
                            fontSize: 13,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: isToday ? AppTheme.primary : AppTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildQuickStats() {
    return Consumer2<NutritionProvider, WorkoutProvider>(
      builder: (context, nutrition, workout, _) {
        return Row(
          children: [
            _buildStatCard(
              'Workouts',
              '${workout.todayWorkoutCount}',
              Icons.fitness_center_rounded,
              AppTheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            _buildStatCard(
              'Burned',
              '${workout.totalCaloriesBurned.toInt()}',
              Icons.local_fire_department_rounded,
              AppTheme.caloriesColor,
            ),
            const SizedBox(width: AppSpacing.md),
            _buildStatCard(
              'Water',
              '${nutrition.hydrationGlasses}',
              Icons.water_drop_rounded,
              AppTheme.secondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Log Food',
                Icons.restaurant_rounded,
                AppTheme.accent,
                () => widget.onNavigate(1),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildActionButton(
                'Log Workout',
                Icons.fitness_center_rounded,
                AppTheme.primary,
                () => widget.onNavigate(3),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildActionButton(
                'Recipes',
                Icons.menu_book_rounded,
                AppTheme.warning,
                () => widget.onNavigate(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.1),
              duration: AppDurations.fast,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(icon, color: color, size: 24),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydration() {
    return Consumer<NutritionProvider>(
      builder: (context, nutrition, _) {
        final progress = (nutrition.hydrationGlasses / 8).clamp(0.0, 1.0);
        
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: AppTheme.secondary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Text(
                        'Hydration',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${nutrition.hydrationGlasses}/8 glasses',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.secondary,
                                AppTheme.secondary.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHydrationBtn(Icons.remove_rounded, () {
                    nutrition.decrementHydration();
                    nutrition.saveHydration();
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Text(
                      '${nutrition.hydrationGlasses}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildHydrationBtn(Icons.add_rounded, () {
                    nutrition.incrementHydration();
                    nutrition.saveHydration();
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHydrationBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.secondary, size: 24),
      ),
    );
  }
}