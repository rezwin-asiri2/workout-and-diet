import 'package:flutter/material.dart';

class MacroSummaryCard extends StatelessWidget {
  final double consumedCalories;
  final double goalCalories;
  final double protein;
  final double carbs;
  final double fat;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;

  const MacroSummaryCard({
    super.key,
    required this.consumedCalories,
    required this.goalCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.proteinGoal = 50,
    this.carbsGoal = 250,
    this.fatGoal = 65,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMacroBar(
            'Calories',
            consumedCalories,
            goalCalories,
            const Color(0xFF00C896),
          ),
          const SizedBox(height: 16),
          _buildMacroBar(
            'Protein',
            protein,
            proteinGoal,
            const Color(0xFF4FC3F7),
          ),
          const SizedBox(height: 16),
          _buildMacroBar(
            'Carbs',
            carbs,
            carbsGoal,
            const Color(0xFFFFA726),
          ),
          const SizedBox(height: 16),
          _buildMacroBar(
            'Fat',
            fat,
            fatGoal,
            const Color(0xFFEF5350),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, double value, double goal, Color color) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}