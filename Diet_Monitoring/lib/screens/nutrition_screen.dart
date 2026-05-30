import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/keys/api_keys.dart';
import '../config/theme.dart';
import '../models/food_item.dart';
import '../services/spoonacular_service.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/food_search_card.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpoonacularService _service = SpoonacularService();
  List<IngredientSearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  bool _showSearch = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
    });
    try {
      final apiKey = ApiKeys.spoonacular;
      final results = await _service.searchIngredients(query, apiKey);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('DAILY_API_QUOTA_REACHED')
            ? 'Daily API quota reached'
            : 'Search failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _showNutritionDetails(IngredientSearchResult ingredient) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
    try {
      final apiKey = ApiKeys.spoonacular;
      final food = await _service.getIngredientNutrition(ingredient.id, apiKey);
      if (mounted) {
        Navigator.pop(context);
        _showAddFoodDialog(food);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get nutrition info')),
        );
      }
    }
  }

  void _showAddFoodDialog(FoodItem food) {
    MealType selectedMealType = _getCurrentMealType();
    double servingAmount = food.servingSize > 0 ? food.servingSize : 100;
    final amountController = TextEditingController(
      text: servingAmount.toInt().toString(),
    );
    final caloriesPerServing = food.calories;
    final proteinPerServing = food.protein;
    final carbsPerServing = food.carbs;
    final fatPerServing = food.fat;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final amount =
              double.tryParse(amountController.text) ?? servingAmount;
          final multiplier =
              amount / (food.servingSize > 0 ? food.servingSize : 100);
          final displayCalories = caloriesPerServing * multiplier;
          final displayProtein = proteinPerServing * multiplier;
          final displayCarbs = carbsPerServing * multiplier;
          final displayFat = fatPerServing * multiplier;

          return Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: AppTheme.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          food.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Text(
                        'Serving: ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: AppTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'g (base: ${food.servingSize.toInt()}g)',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Meal Type',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: MealType.values.map((type) {
                      final isSelected = selectedMealType == type;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedMealType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? type.color.withValues(alpha: 0.2)
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? type.color
                                  : AppTheme.textTertiary.withValues(
                                      alpha: 0.3,
                                    ),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type.icon,
                                color: isSelected
                                    ? type.color
                                    : AppTheme.textTertiary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  color: isSelected
                                      ? type.color
                                      : AppTheme.textTertiary,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutrientItem(
                        'Calories',
                        displayCalories.toStringAsFixed(0),
                        'kcal',
                        AppTheme.caloriesColor,
                      ),
                      _buildNutrientItem(
                        'Protein',
                        displayProtein.toStringAsFixed(1),
                        'g',
                        AppTheme.proteinColor,
                      ),
                      _buildNutrientItem(
                        'Carbs',
                        displayCarbs.toStringAsFixed(1),
                        'g',
                        AppTheme.carbsColor,
                      ),
                      _buildNutrientItem(
                        'Fat',
                        displayFat.toStringAsFixed(1),
                        'g',
                        AppTheme.fatColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final adjustedFood = food.copyWith(
                              mealType: selectedMealType,
                              calories: displayCalories,
                              protein: displayProtein,
                              carbs: displayCarbs,
                              fat: displayFat,
                              servingSize: amount,
                            );
                            context.read<NutritionProvider>().addFood(
                              adjustedFood,
                            );
                            Navigator.pop(dialogContext);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: AppTheme.buttonShadow,
                            ),
                            child: const Center(
                              child: Text(
                                'Add Food',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  MealType _getCurrentMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  Widget _buildNutrientItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showSearch) _buildSearchBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.accentGradient.createShader(b),
                child: const Text(
                  'Nutrition',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _searchResults = [];
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _showSearch ? AppTheme.primaryGradient : null,
                    color: _showSearch ? null : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _showSearch ? AppTheme.buttonShadow : null,
                  ),
                  child: Icon(
                    _showSearch ? Icons.close_rounded : Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Consumer<NutritionProvider>(
            builder: (context, nutrition, _) {
              final consumed = nutrition.totalCalories.toInt();
              final goal = nutrition.calorieGoal;
              final remaining = (goal - consumed).clamp(0, goal);
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$remaining',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'kcal remaining',
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$consumed / $goal',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (consumed / goal).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.textTertiary.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accent,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search ingredients...',
          hintStyle: TextStyle(color: AppTheme.textTertiary),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          suffixIcon: GestureDetector(
            onTap: _search,
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        onSubmitted: (_) => _search(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    if (_error != null)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    if (_searchResults.isNotEmpty)
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) => FoodSearchCard(
          title: _searchResults[index].name,
          imageUrl: _searchResults[index].image,
          onTap: () => _showNutritionDetails(_searchResults[index]),
          trailing: const Icon(
            Icons.add_circle_outline_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
        ),
      );
    return _buildFoodLog();
  }

  Widget _buildFoodLog() {
    return Consumer<NutritionProvider>(
      builder: (context, nutrition, _) {
        if (nutrition.foodLog.isEmpty)
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildMacroSummary(nutrition),
              const SizedBox(height: AppSpacing.xxl),
              _buildEmptyState(),
            ],
          );
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildMacroSummary(nutrition),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Log",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${nutrition.foodLog.length} items',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...nutrition.foodLog.asMap().entries.map((entry) {
              final food = entry.value;
              final index = entry.key;
              final mealColor = food.mealType.color;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Dismissible(
                  key: Key('food_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: AppTheme.error,
                    ),
                  ),
                  onDismissed: (_) => nutrition.removeFood(index),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: mealColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: mealColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${food.calories.toInt()} kcal',
                                    style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'P: ${food.protein.toInt()}g',
                                    style: TextStyle(
                                      color: AppTheme.proteinColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'C: ${food.carbs.toInt()}g',
                                    style: TextStyle(
                                      color: AppTheme.carbsColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'F: ${food.fat.toInt()}g',
                                    style: TextStyle(
                                      color: AppTheme.fatColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => nutrition.removeFood(index),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.textTertiary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMacroSummary(NutritionProvider nutrition) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _macroItem(
            'Calories',
            '${nutrition.totalCalories.toInt()}',
            AppTheme.caloriesColor,
          ),
          Container(
            height: 40,
            width: 1,
            color: AppTheme.textTertiary.withValues(alpha: 0.2),
          ),
          _macroItem(
            'Protein',
            '${nutrition.totalProtein.toInt()}g',
            AppTheme.proteinColor,
          ),
          Container(
            height: 40,
            width: 1,
            color: AppTheme.textTertiary.withValues(alpha: 0.2),
          ),
          _macroItem(
            'Carbs',
            '${nutrition.totalCarbs.toInt()}g',
            AppTheme.carbsColor,
          ),
          Container(
            height: 40,
            width: 1,
            color: AppTheme.textTertiary.withValues(alpha: 0.2),
          ),
          _macroItem(
            'Fat',
            '${nutrition.totalFat.toInt()}g',
            AppTheme.fatColor,
          ),
        ],
      ),
    );
  }

  Widget _macroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: AppTheme.accent.withValues(alpha: 0.5),
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'No food logged yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Search for food to start tracking',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
