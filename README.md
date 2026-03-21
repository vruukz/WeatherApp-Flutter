# WeatherApp 🌤️

A cross-platform weather app built with Flutter, available on Android and Windows.
Displays real-time weather data with smooth animations, matching a minimal dark aesthetic.

![Flutter](https://img.shields.io/badge/Flutter-3.41.5-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux-green)

## Features

- Real-time current weather via OpenWeatherMap API
- Animated temperature display
- Hourly forecast (next 24h) with rain chance
- 5-day forecast with min/max temperatures
- Rain quantity and probability for next 3 hours
- Favorite cities — save and quick-load
- In-app update notifications
- Language toggle — English / Romanian
- Temperature unit toggle — Celsius / Fahrenheit
- Android home screen widget with clock, date, temperature and rain chance
- Minimal dark UI matching portfolio color scheme

## Screenshots

<img width="1913" height="671" alt="image" src="https://github.com/user-attachments/assets/a3a8490f-61be-4978-86fe-2b2c0fbb84ad" />

## Setup

1. Clone the repo
2. Get a free API key at [openweathermap.org](https://openweathermap.org/api)
3. Create a `.env` file in the root:
```
WEATHER_API_KEY=your_key_here
```
4. Install dependencies:
```bash
flutter pub get
```
5. Run:
```bash
flutter run
```

## Build

**Android APK:**
```bash
flutter build apk --release
```

**Windows EXE:**
```bash
flutter build windows
```

**Linux:**
```bash
flutter build linux
```

## Android Widget

After installing the APK, long press your home screen → Widgets → find WeatherApp and add it.
The widget shows current time, date, city, temperature and rain chance for the next 3 hours.
It updates automatically when you search a city in the app.

## Tech Stack

- Flutter / Dart
- OpenWeatherMap API
- flutter_dotenv
- http package
- shared_preferences
- home_widget

## Version

Current: 1.0.0
