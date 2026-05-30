import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/weather_service.dart';

class WeatherAdvisoryCard extends StatelessWidget {
  final WeatherData? weather;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const WeatherAdvisoryCard({
    super.key,
    this.weather,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cloud_off_rounded, color: AppTheme.error, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load weather',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorMessage!,
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (weather == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.textTertiary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_city_rounded, color: AppTheme.textTertiary, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No location set',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add your city in Settings to see weather',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final colorValue = weather!.advisoryColor;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Color(colorValue).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(
            _getWeatherIcon(weather!.conditionCode),
            color: Color(colorValue),
            size: 32,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather!.city,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${weather!.temperature.round()}°C • ${weather!.description}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Color(colorValue).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAdvisoryIcon(weather!.conditionCode),
                      color: Color(colorValue),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      weather!.workoutAdvisory,
                      style: TextStyle(
                        color: Color(colorValue),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 800) return Icons.wb_sunny_rounded;
    if (code >= 801 && code <= 804) return Icons.wb_cloudy_rounded;
    if (code >= 500 && code <= 531) return Icons.water_drop_rounded;
    if (code >= 200 && code <= 299) return Icons.flash_on_rounded;
    if (code >= 600 && code <= 622) return Icons.ac_unit_rounded;
    return Icons.cloud_rounded;
  }

  IconData _getAdvisoryIcon(int code) {
    if (code == 800) return Icons.directions_run_rounded;
    if (code >= 801 && code <= 804) return Icons.directions_walk_rounded;
    if (code >= 500 && code <= 531) return Icons.home_rounded;
    if (code >= 200 && code <= 299) return Icons.warning_rounded;
    if (code >= 600 && code <= 622) return Icons.ac_unit_rounded;
    return Icons.info_rounded;
  }
}