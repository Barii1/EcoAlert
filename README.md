# EcoAlert - Predict. Prepare. Protect.

AI-powered environmental hazard prediction and alert system for Pakistan.

## Features

- 🌊 **Flood Prediction**: Real-time flood risk assessment and alerts
- 🌫️ **Air Quality Monitoring**: Live AQI data with health recommendations
- ⛈️ **Cloudburst Warnings**: Sudden heavy rainfall predictions
- 🗺️ **Interactive Hazard Map**: Visualize danger zones and safe routes
- 📱 **Push Notifications**: Instant alerts for environmental hazards
- 📚 **Safety Education**: Learn how to prepare for different hazards

## Tech Stack

- **Frontend**: Flutter (Mobile + Web)
- **Backend**: Firebase (Cloud Functions, Firestore, FCM)
- **ML Models**: Python (LSTM, XGBoost, SVM)
- **Maps**: Google Maps Flutter
- **State Management**: Provider

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile)
- Firebase account

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ecoalert
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in respective directories
   - Enable Firebase Authentication, Firestore, and Cloud Messaging

4. Run the app:
```bash
# For mobile
flutter run

# For web
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── map_screen.dart
│   ├── alerts_screen.dart
│   └── learn_screen.dart
├── widgets/                  # Reusable widgets
│   ├── hazard_card.dart
│   ├── alert_card.dart
│   └── safety_guide_card.dart
├── providers/                # State management
│   ├── theme_provider.dart
│   ├── location_provider.dart
│   └── alert_provider.dart
└── models/                   # Data models
    └── alert_model.dart
```

## Configuration

### Google Maps API Key

1. Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Maps SDK for Android/iOS
3. Add to `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

### Firebase Setup

1. Add Firebase to your Flutter app
2. Enable required services:
   - Authentication
   - Cloud Firestore
   - Cloud Functions
   - Cloud Messaging

## Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
firebase deploy --only hosting
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Team

- Muhammad Hassaan Bari (261934233)
- Muhammad Bilal (251687216)
- Rehman Ibrahim Zafar (261936230)

**Advisors:**
- Ms. Rabranea Bqa (Primary)
- Ms. Umber Nisar (Secondary)

## License

This project is part of a Final Year Project (FYP) at [University Name].

## Acknowledgments

- Pakistan Meteorological Department (PMD)
- OpenWeatherMap API
- NASA GPM
- OpenAQ
