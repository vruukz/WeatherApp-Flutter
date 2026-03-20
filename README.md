# WeatherApp 🌤️

A cross-platform weather app built with Flutter, available on Android and Windows.
Displays real-time weather data with smooth animations, matching a minimal dark aesthetic.

![Flutter](https://img.shields.io/badge/Flutter-3.41.5-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-green)

## Features

- Real-time weather data via OpenWeatherMap API
- Animated temperature display
- Humidity and wind info
- In-app update notifications
- Minimal dark UI

## Screenshots

<img width="1914" height="1026" alt="image" src="https://github.com/user-attachments/assets/254d3f1d-1999-4d91-8f1d-6031e368791d" />


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

## Tech Stack

- Flutter / Dart
- OpenWeatherMap API
- flutter_dotenv
- http package

## Version

Current: 1.0.0
