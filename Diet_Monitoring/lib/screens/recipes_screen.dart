import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/keys/api_keys.dart';
import '../config/theme.dart';
import '../models/recipe.dart';
import '../services/spoonacular_service.dart';
import '../widgets/common_widgets.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpoonacularService _service = SpoonacularService();
  List<Recipe> _recipes = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _searchRecipes() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _recipes = [];
    });

    try {
      final apiKey = ApiKeys.spoonacular;
      final results = await _service.searchRecipes(query, apiKey);
      setState(() {
        _recipes = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('DAILY_API_QUOTA_REACHED')
            ? 'Daily API quota reached (150 calls). Try again tomorrow.'
            : 'Failed to search: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => AppTheme.warningGradient.createShader(bounds),
                        child: const Text(
                          'Recipes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded, color: AppTheme.textTertiary, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find healthy and delicious recipes',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: _searchRecipes,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                onSubmitted: (_) => _searchRecipes(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: _error!,
        iconColor: AppTheme.error,
        action: ElevatedButton(
          onPressed: _searchRecipes,
          child: const Text('Retry'),
        ),
      );
    }

    if (_recipes.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_rounded,
        title: 'Search for recipes',
        subtitle: 'Find healthy meals and cooking ideas',
        iconColor: AppTheme.warning,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _recipes.length,
      itemBuilder: (context, index) => _buildRecipeCard(_recipes[index]),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRecipeDetail(recipe),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _buildImage(recipe),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _buildInfoChip(Icons.timer_rounded, '${recipe.readyInMinutes} min', AppTheme.secondary),
                          const SizedBox(width: AppSpacing.sm),
                          _buildInfoChip(Icons.local_fire_department_rounded, '${recipe.calories.toStringAsFixed(0)} kcal', AppTheme.caloriesColor),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _buildMacroChip('P', '${recipe.protein.toInt()}g', AppTheme.proteinColor),
                          const SizedBox(width: AppSpacing.xs),
                          _buildMacroChip('C', '${recipe.carbs.toInt()}g', AppTheme.carbsColor),
                          const SizedBox(width: AppSpacing.xs),
                          _buildMacroChip('F', '${recipe.fat.toInt()}g', AppTheme.fatColor),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textTertiary, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Recipe recipe) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: recipe.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: recipe.imageUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 80,
                height: 80,
                color: AppTheme.surfaceLight,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                color: AppTheme.surfaceLight,
                child: const Icon(Icons.restaurant, color: AppTheme.textTertiary),
              ),
            )
          : Container(
              width: 80,
              height: 80,
              color: AppTheme.surfaceLight,
              child: const Icon(Icons.restaurant, color: AppTheme.textTertiary),
            ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _openRecipeDetail(Recipe recipe) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );

    try {
      final apiKey = ApiKeys.spoonacular;
      final details = await _service.getRecipeDetails(recipe.id, apiKey);

      if (mounted) {
        Navigator.pop(context);
        _showRecipeDetail(details);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('DAILY_API_QUOTA_REACHED')
                ? 'Daily API quota reached'
                : 'Failed to get recipe'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showRecipeDetail(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (recipe.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: CachedNetworkImage(
                        imageUrl: recipe.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _buildDetailChip(Icons.timer_rounded, '${recipe.readyInMinutes} min', AppTheme.secondary),
                      const SizedBox(width: AppSpacing.sm),
                      _buildDetailChip(Icons.local_fire_department_rounded, '${recipe.calories.toStringAsFixed(0)} kcal', AppTheme.caloriesColor),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroDetail('Calories', '${recipe.calories.toInt()}', AppTheme.caloriesColor),
                        _buildMacroDetail('Protein', '${recipe.protein.toInt()}g', AppTheme.proteinColor),
                        _buildMacroDetail('Carbs', '${recipe.carbs.toInt()}g', AppTheme.carbsColor),
                        _buildMacroDetail('Fat', '${recipe.fat.toInt()}g', AppTheme.fatColor),
                      ],
                    ),
                  ),
                  if (recipe.ingredients.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Ingredients',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...recipe.ingredients.map((ing) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              ing.original ?? ing.name,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  if (recipe.steps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...recipe.steps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${step.number}',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              step.step,
                              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDetail(String label, String value, Color color) {
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
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}