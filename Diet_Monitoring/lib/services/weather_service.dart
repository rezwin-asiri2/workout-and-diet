import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String city;
  final String description;
  final double temperature;
  final int conditionCode;
  final String iconCode;

  WeatherData({
    required this.city,
    required this.description,
    required this.temperature,
    required this.conditionCode,
    required this.iconCode,
  });

  String get workoutAdvisory {
    if (conditionCode == 800) {
      return 'Perfect for outdoor workout ☀️';
    } else if (conditionCode >= 801 && conditionCode <= 804) {
      return 'Good conditions, go for it 🌤';
    } else if (conditionCode >= 500 && conditionCode <= 531) {
      return 'Rainy — stay indoors 🌧';
    } else if (conditionCode >= 200 && conditionCode <= 299) {
      return 'Thunderstorm — avoid outdoors ⛈';
    } else if (conditionCode >= 600 && conditionCode <= 622) {
      return 'Snowy — be careful outside ❄️';
    } else {
      return 'Check conditions before heading out 🌡';
    }
  }

  int get advisoryColor {
    if (conditionCode == 800) {
      return 0xFF00C896;
    } else if (conditionCode >= 801 && conditionCode <= 804) {
      return 0xFF90EE90;
    } else if (conditionCode >= 500 && conditionCode <= 531) {
      return 0xFFFFA500;
    } else if (conditionCode >= 200 && conditionCode <= 299) {
      return 0xFFFF0000;
    } else if (conditionCode >= 600 && conditionCode <= 622) {
      return 0xFF87CEEB;
    } else {
      return 0xFF808080;
    }
  }
}

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherData?> getWeather(String city, String apiKey) async {
    if (apiKey.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.parse('$_baseUrl?q=$city&appid=$apiKey&units=metric');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData(
          city: data['name'] ?? city,
          description: data['weather'][0]['description'] ?? '',
          temperature: (data['main']['temp'] as num).toDouble(),
          conditionCode: data['weather'][0]['id'] as int,
          iconCode: data['weather'][0]['icon'] ?? '01d',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else {
        throw Exception('Failed to fetch weather: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}