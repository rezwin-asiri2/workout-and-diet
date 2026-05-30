import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _buildImage(),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(Icons.timer, color: AppTheme.textSecondary, size: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${recipe.readyInMinutes} min',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Icon(Icons.local_fire_department, color: AppTheme.textSecondary, size: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${recipe.calories.toStringAsFixed(0)} kcal',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.textTertiary, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (recipe.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: CachedNetworkImage(
          imageUrl: recipe.imageUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (context, url) => _placeholderWidget(),
          errorWidget: (context, url, error) => _placeholderWidget(),
        ),
      );
    }
    return _placeholderWidget();
  }

  Widget _placeholderWidget() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(Icons.restaurant, color: AppTheme.accent, size: 32),
    );
  }
}