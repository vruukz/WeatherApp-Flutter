import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await dotenv.load(fileName: ".env");
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

class _WeatherHomeState extends State<WeatherHome> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
  late TabController _tabController;

  List<String> favorites = [];
  String city = '';
  String country = '';
  String description = '';
  String humidity = '';
  String wind = '';
  double? temperature;
  double? rainNextHour;
  bool loading = false;
  String error = '';
  bool isCelsius = true;
  String language = 'en';

  List<Map<String, dynamic>> hourlyForecast = [];
  List<Map<String, dynamic>> dailyForecast = [];

  // Translations
  Map<String, Map<String, String>> translations = {
    'en': {
      'title': 'WEATHER',
      'search': 'Enter city...',
      'go': 'GO',
      'favorites': 'FAVORITES',
      'humidity': 'HUMIDITY',
      'wind': 'WIND',
      'rain1h': 'RAIN/1H',
      'now': 'NOW',
      'hourly': 'HOURLY',
      'days': '5 DAYS',
      'description': 'Description',
      'rainNext': 'Rain next 3h',
      'cityNotFound': 'City not found',
      'error': 'Something went wrong',
      'updateTitle': 'Update Available',
      'updateMsg': 'is available!',
      'later': 'Later',
      'download': 'Download',
      'settings': 'Settings',
      'language': 'Language',
      'unit': 'Temperature Unit',
      'rainChance': 'Rain chance',
    },
    'ro': {
      'title': 'VREME',
      'search': 'Introdu un oraș...',
      'go': 'OK',
      'favorites': 'FAVORITE',
      'humidity': 'UMIDITATE',
      'wind': 'VÂNT',
      'rain1h': 'PLOAIE/1H',
      'now': 'ACUM',
      'hourly': 'PE ORE',
      'days': '5 ZILE',
      'description': 'Descriere',
      'rainNext': 'Ploaie următoarele 3h',
      'cityNotFound': 'Orașul nu a fost găsit',
      'error': 'Ceva a mers greșit',
      'updateTitle': 'Actualizare Disponibilă',
      'updateMsg': 'este disponibil!',
      'later': 'Mai târziu',
      'download': 'Descarcă',
      'settings': 'Setări',
      'language': 'Limbă',
      'unit': 'Unitate Temperatură',
      'rainChance': 'Șansă ploaie',
    },
  };

  String t(String key) => translations[language]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    checkForUpdates();
    loadFavorites();
    loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isCelsius = prefs.getBool('isCelsius') ?? true;
      language = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', isCelsius);
    await prefs.setString('language', language);
  }

  double convertTemp(double celsius) {
    if (isCelsius) return celsius;
    return (celsius * 9 / 5) + 32;
  }

  String tempUnit() => isCelsius ? '°C' : '°F';

  Future<void> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/vruukz/WeatherApp-Flutter/master/version.json'
      ));
      final data = json.decode(response.body);
      final latestVersion = data['version'];

      if (latestVersion != '1.0.0') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF161616),
            title: Text(t('updateTitle'), style: const TextStyle(color: Color(0xFFC8F060))),
            content: Text('Version $latestVersion ${t('updateMsg')}', style: const TextStyle(color: Color(0xFF666666))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('later'), style: const TextStyle(color: Color(0xFF666666))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('download'), style: const TextStyle(color: Color(0xFFC8F060))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // silently fail
    }
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> toggleFavorite(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favorites.contains(cityName)) {
        favorites.remove(cityName);
      } else {
        favorites.add(cityName);
      }
    });
    await prefs.setStringList('favorites', favorites);
  }

  Future<void> fetchWeather() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() { loading = true; error = ''; });

    try {
      final currentUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$query&appid=$apiKey&units=metric&lang=$language'
      );
      final currentResponse = await http.get(currentUrl);
      final currentData = json.decode(currentResponse.body);

      final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$query&appid=$apiKey&units=metric&lang=$language'
      );
      final forecastResponse = await http.get(forecastUrl);
      final forecastData = json.decode(forecastResponse.body);

      if (currentResponse.statusCode == 200) {
        final List hourlyList = forecastData['list'];

        final hourly = hourlyList.take(8).map((h) => {
          'time': DateTime.fromMillisecondsSinceEpoch(h['dt'] * 1000),
          'temp': h['main']['temp'].toDouble(),
          'description': h['weather'][0]['description'],
          'rain': h.containsKey('rain') ? (h['rain']['3h'] ?? 0.0) : 0.0,
          'rainChance': ((h['pop'] ?? 0.0) * 100).toInt(),
        }).toList();

        Map<String, List> dayGroups = {};
        for (var item in hourlyList) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dayKey = '${date.year}-${date.month}-${date.day}';
          if (!dayGroups.containsKey(dayKey)) dayGroups[dayKey] = [];
          dayGroups[dayKey]!.add(item);
        }

        final daily = dayGroups.entries.take(5).map((entry) {
          final items = entry.value;
          final temps = items.map((i) => i['main']['temp'].toDouble()).toList();
          final maxTemp = temps.reduce((a, b) => a > b ? a : b);
          final minTemp = temps.reduce((a, b) => a < b ? a : b);
          final desc = items[items.length ~/ 2]['weather'][0]['description'];
          final date = DateTime.fromMillisecondsSinceEpoch(items[0]['dt'] * 1000);
          final totalRain = items.fold(0.0, (sum, i) =>
            sum + (i.containsKey('rain') ? (i['rain']['3h'] ?? 0.0) : 0.0));
          final maxRainChance = items.map((i) => ((i['pop'] ?? 0.0) * 100).toInt()).reduce((a, b) => a > b ? a : b);
          return {
            'date': date,
            'maxTemp': maxTemp,
            'minTemp': minTemp,
            'description': desc,
            'rain': totalRain,
            'rainChance': maxRainChance,
          };
        }).toList();

        final nextHourRain = hourly.isNotEmpty ? (hourly[0]['rain'] as double) : 0.0;

        setState(() {
          city = currentData['name'];
          country = currentData['sys']['country'];
          temperature = currentData['main']['temp'].toDouble();
          description = currentData['weather'][0]['description'];
          humidity = '${currentData['main']['humidity']}%';
          wind = '${currentData['wind']['speed']} m/s';
          rainNextHour = nextHourRain;
          hourlyForecast = hourly.cast<Map<String, dynamic>>();
          dailyForecast = daily.cast<Map<String, dynamic>>();
          loading = false;
        });
      } else {
        setState(() { error = t('cityNotFound'); loading = false; });
      }
    } catch (e) {
      setState(() { error = t('error'); loading = false; });
    }
  }

  void showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('settings'), style: const TextStyle(fontSize: 11, letterSpacing: 4, color: Color(0xFFC8F060))),
              const SizedBox(height: 32),

              // Language
              Text(t('language'), style: const TextStyle(fontSize: 12, color: Color(0xFF666666), letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _settingChip('English', language == 'en', () {
                    setModalState(() => language = 'en');
                    setState(() => language = 'en');
                    saveSettings();
                  }),
                  const SizedBox(width: 8),
                  _settingChip('Română', language == 'ro', () {
                    setModalState(() => language = 'ro');
                    setState(() => language = 'ro');
                    saveSettings();
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Temperature unit
              Text(t('unit'), style: const TextStyle(fontSize: 12, color: Color(0xFF666666), letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _settingChip('Celsius °C', isCelsius, () {
                    setModalState(() => isCelsius = true);
                    setState(() => isCelsius = true);
                    saveSettings();
                  }),
                  const SizedBox(width: 8),
                  _settingChip('Fahrenheit °F', !isCelsius, () {
                    setModalState(() => isCelsius = false);
                    setState(() => isCelsius = false);
                    saveSettings();
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? const Color(0xFFC8F060) : const Color(0xFF252525)),
          borderRadius: BorderRadius.circular(4),
          color: selected ? const Color(0xFFC8F060).withOpacity(0.1) : const Color(0xFF0D0D0D),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? const Color(0xFFC8F060) : const Color(0xFF666666),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  String _formatHour(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:00';

  String _formatDay(DateTime dt) {
    if (language == 'ro') {
      const days = ['Lun', 'Mar', 'Mie', 'Joi', 'Vin', 'Sâm', 'Dum'];
      return days[dt.weekday - 1];
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
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
              // Title row with settings cog
              Row(
                children: [
                  Text(
                    t('title'),
                    style: const TextStyle(fontSize: 11, letterSpacing: 6, color: Color(0xFFC8F060)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: showSettings,
                    child: const Icon(Icons.settings, color: Color(0xFF666666), size: 20),
                  ),
                ],
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
                        hintText: t('search'),
                        hintStyle: const TextStyle(color: Color(0xFF666666)),
                        filled: true,
                        fillColor: const Color(0xFF161616),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF252525))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF252525))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFC8F060))),
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
                    child: Text(t('go'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Favorites
              if (favorites.isNotEmpty) ...[
                Text(t('favorites'), style: const TextStyle(fontSize: 10, letterSpacing: 4, color: Color(0xFF666666))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: favorites.map((fav) => GestureDetector(
                    onTap: () { _controller.text = fav; fetchWeather(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF252525)),
                        borderRadius: BorderRadius.circular(4),
                        color: const Color(0xFF161616),
                      ),
                      child: Text(fav, style: const TextStyle(fontSize: 11, color: Color(0xFFE8E2D9), letterSpacing: 1)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],

              if (loading) const Center(child: CircularProgressIndicator(color: Color(0xFFC8F060))),
              if (error.isNotEmpty) Text(error, style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),

              if (temperature != null && !loading) ...[
                Row(
                  children: [
                    Text('$city, $country', style: const TextStyle(fontFamily: 'serif', fontSize: 28, color: Color(0xFFE8E2D9), fontStyle: FontStyle.italic)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => toggleFavorite(city),
                      child: Icon(favorites.contains(city) ? Icons.star : Icons.star_border, color: const Color(0xFFC8F060), size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: convertTemp(temperature!)),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Text(
                      '${value.toStringAsFixed(0)}${tempUnit()}',
                      style: const TextStyle(fontFamily: 'serif', fontSize: 72, color: Color(0xFFC8F060), height: 1),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(description.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 3, color: Color(0xFF666666))),
                const SizedBox(height: 24),
                Container(height: 1, color: const Color(0xFF252525)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statItem(t('humidity'), humidity),
                    const SizedBox(width: 32),
                    _statItem(t('wind'), wind),
                    const SizedBox(width: 32),
                    _statItem(t('rain1h'), rainNextHour != null ? '${rainNextHour!.toStringAsFixed(1)} mm' : '0 mm'),
                  ],
                ),
                const SizedBox(height: 24),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFC8F060),
                  unselectedLabelColor: const Color(0xFF666666),
                  indicatorColor: const Color(0xFFC8F060),
                  labelStyle: const TextStyle(fontSize: 10, letterSpacing: 2),
                  tabs: [Tab(text: t('now')), Tab(text: t('hourly')), Tab(text: t('days'))],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // NOW
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(t('description'), description),
                            _infoRow(t('humidity'), humidity),
                            _infoRow(t('wind'), wind),
                            _infoRow(t('rainNext'), '${rainNextHour?.toStringAsFixed(1) ?? 0} mm'),
                          ],
                        ),
                      ),

                      // HOURLY
                      ListView.builder(
                        itemCount: hourlyForecast.length,
                        itemBuilder: (context, index) {
                          final h = hourlyForecast[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(width: 48, child: Text(_formatHour(h['time']), style: const TextStyle(fontSize: 11, color: Color(0xFF666666), letterSpacing: 1))),
                                Text('${convertTemp(h['temp'] as double).toStringAsFixed(0)}${tempUnit()}', style: const TextStyle(fontSize: 14, color: Color(0xFFE8E2D9))),
                                const SizedBox(width: 12),
                                Expanded(child: Text((h['description'] as String).toUpperCase(), style: const TextStyle(fontSize: 9, color: Color(0xFF666666), letterSpacing: 1))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if ((h['rain'] as double) > 0)
                                      Text('${(h['rain'] as double).toStringAsFixed(1)}mm', style: const TextStyle(fontSize: 10, color: Color(0xFFC8F060))),
                                    Text('${h['rainChance']}%', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // 5 DAYS
                      ListView.builder(
                        itemCount: dailyForecast.length,
                        itemBuilder: (context, index) {
                          final d = dailyForecast[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(width: 40, child: Text(_formatDay(d['date']), style: const TextStyle(fontSize: 11, color: Color(0xFF666666), letterSpacing: 1))),
                                const SizedBox(width: 8),
                                Text('${convertTemp(d['maxTemp'] as double).toStringAsFixed(0)}°', style: const TextStyle(fontSize: 14, color: Color(0xFFC8F060))),
                                const SizedBox(width: 6),
                                Text('${convertTemp(d['minTemp'] as double).toStringAsFixed(0)}°', style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                                const SizedBox(width: 12),
                                Expanded(child: Text((d['description'] as String).toUpperCase(), style: const TextStyle(fontSize: 9, color: Color(0xFF666666), letterSpacing: 1))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if ((d['rain'] as double) > 0)
                                      Text('${(d['rain'] as double).toStringAsFixed(1)}mm', style: const TextStyle(fontSize: 10, color: Color(0xFFC8F060))),
                                    Text('${d['rainChance']}%', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 2, color: Color(0xFF666666))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFE8E2D9))),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label    ', style: const TextStyle(fontSize: 11, color: Color(0xFF666666), letterSpacing: 1)),
          Text(value, style: const TextStyle(fontSize: 11, color: Color(0xFFE8E2D9))),
        ],
      ),
    );
  }
}