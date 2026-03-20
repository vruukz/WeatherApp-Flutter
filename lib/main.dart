import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC8F060),
          surface: const Color(0xFF161616),
        ),
        fontFamily: 'monospace',
      ),
      home: const WeatherHome(),
    );
  }
}

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  final TextEditingController _controller = TextEditingController();
  final String apiKey = '350cfc9570c1e7fa4a0c1dde35259781';

  String city = '';
  String country = '';
  String description = '';
  String humidity = '';
  String wind = '';
  double? temperature;
  bool loading = false;
  String error = '';

  Future<void> fetchWeather() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() { loading = true; error = ''; });

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$query&appid=$apiKey&units=metric'
      );
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          city = data['name'];
          country = data['sys']['country'];
          temperature = data['main']['temp'].toDouble();
          description = data['weather'][0]['description'];
          humidity = '${data['main']['humidity']}%';
          wind = '${data['wind']['speed']} m/s';
          loading = false;
        });
      } else {
        setState(() { error = 'City not found'; loading = false; });
      }
    } catch (e) {
      setState(() { error = 'Something went wrong'; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'WEATHER',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 6,
                  color: Color(0xFFC8F060),
                ),
              ),
              const SizedBox(height: 32),

              // Search bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Color(0xFFE8E2D9)),
                      decoration: InputDecoration(
                        hintText: 'Enter city...',
                        hintStyle: const TextStyle(color: Color(0xFF666666)),
                        filled: true,
                        fillColor: const Color(0xFF161616),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFF252525)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFF252525)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFFC8F060)),
                        ),
                      ),
                      onSubmitted: (_) => fetchWeather(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: fetchWeather,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8F060),
                      foregroundColor: const Color(0xFF0D0D0D),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('GO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Loading
              if (loading)
                const Center(child: CircularProgressIndicator(color: Color(0xFFC8F060))),

              // Error
              if (error.isNotEmpty)
                Text(error, style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),

              // Weather data
              if (temperature != null && !loading) ...[
                Text(
                  '$city, $country',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 28,
                    color: Color(0xFFE8E2D9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: temperature!),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Text(
                      '${value.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 72,
                        color: Color(0xFFC8F060),
                        height: 1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  description.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 32),
                Container(height: 1, color: const Color(0xFF252525)),
                const SizedBox(height: 24),
                Text(
                  'HUMIDITY    $humidity',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666), letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  'WIND        $wind',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666), letterSpacing: 1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}