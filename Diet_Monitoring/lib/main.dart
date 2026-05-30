import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/nutrition_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/home_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chatbot_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VitalTrackApp());
}

class VitalTrackApp extends StatelessWidget {
  const VitalTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NutritionProvider()..loadTodayLog()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()..loadTodayLog()),
      ],
      child: MaterialApp(
        title: 'VitalTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _onNavigate(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppDurations.normal,
        switchInCurve: AppAnimations.defaultCurve,
        switchOutCurve: AppAnimations.defaultCurve,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: AppAnimations.smoothCurve)),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(onNavigate: _onNavigate),
              const NutritionScreen(),
              const RecipesScreen(),
              const WorkoutScreen(),
              const ChatbotScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.restaurant_outlined, Icons.restaurant_rounded, 'Food'),
                _buildNavItem(2, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Recipes'),
                _buildNavItem(3, Icons.fitness_center_outlined, Icons.fitness_center_rounded, 'Workout'),
                _buildNavItem(4, Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'AI'),
                _buildNavItem(5, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavigate(index),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.fast,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}