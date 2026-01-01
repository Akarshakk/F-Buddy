# F Buddy Mobile App

Flutter mobile application for the F Buddy finance tracking platform.

## Quick Start

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Configuration

Update API URL in `lib/config/constants.dart`:

```dart
// For Android emulator: 10.0.2.2
// For iOS simulator: localhost  
// For physical device: your computer's IP address
static const String baseUrl = 'http://localhost:5000/api';
```

## Features

- 📊 Real-time expense tracking
- 🥧 Category-wise pie chart visualization
- 📈 7-day income vs expense bar chart
- 📋 Latest 10 expenses table
- 💰 Monthly budget tracking
- 🔐 Secure authentication

## Dependencies

- Provider (State Management)
- FL Chart (Charts & Graphs)
- HTTP (API Communication)
- Flutter Secure Storage (Token Storage)
- Google Fonts (Typography)
- Intl (Date Formatting)
