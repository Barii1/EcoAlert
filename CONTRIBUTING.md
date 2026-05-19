# EcoAlert Development Guidelines

## 🎯 Project Overview
EcoAlert is an AI-powered environmental hazard prediction and alert system for Pakistan. It combines real-time AQI monitoring, flood warnings, and ML-based predictions to provide timely environmental hazard alerts.

**Tech Stack:** Flutter (Frontend) | Firebase (Backend) | Python/ML (Predictions) | Railway (Deployment)

---

## ✅ DO's

### Code Quality
- **Do** use Provider for state management consistently
- **Do** keep providers focused on single responsibility
- **Do** use meaningful variable names that reflect their purpose
- **Do** follow Dart style guide and use `dart format`
- **Do** handle errors gracefully with user-friendly messages
- **Do** add comments only for non-obvious logic (WHY, not WHAT)
- **Do** test critical paths before pushing (alert triggers, auth flows)

### Firebase Integration
- **Do** use FirebaseAuthService for all authentication
- **Do** store user profiles in Firestore under `/users/{uid}`
- **Do** use Firebase Messaging for push notifications
- **Do** validate user permissions before showing admin screens
- **Do** keep API keys in `lib/config/api_keys.dart`

### State Management
- **Do** use `notifyListeners()` only when state actually changes
- **Do** keep providers stateless when possible (use singletons for services)
- **Do** separate data providers from UI providers
- **Do** document provider getters and their return types

### Testing
- **Do** test alert provider changes
- **Do** verify Firebase connectivity before release
- **Do** test on Android and iOS before merging
- **Do** check push notification delivery

### Git Workflow
- **Do** write clear, descriptive commit messages
- **Do** keep commits focused on single features/fixes
- **Do** pull from main before pushing
- **Do** create meaningful branch names: `feature/`, `fix/`, `chore/`

---

## ❌ DON'Ts

### Code Structure
- **Don't** create demo services or mock data in production code
- **Don't** hardcode API keys or credentials (use config files)
- **Don't** duplicate code across providers
- **Don't** add unnecessary abstractions (YAGNI principle)
- **Don't** leave commented-out code; delete or explain with TODO
- **Don't** create deeply nested widget hierarchies without extracting components

### Firebase & Security
- **Don't** bypass Firebase authentication checks
- **Don't** store sensitive data in SharedPreferences unencrypted
- **Don't** commit `.env` files or credentials
- **Don't** trust user input without validation
- **Don't** make unauthenticated API calls to backends

### State Management
- **Don't** mix different state management patterns
- **Don't** call `notifyListeners()` in loops
- **Don't** keep large datasets in memory unnecessarily
- **Don't** make network calls in provider constructors
- **Don't** ignore async/await patterns

### Performance
- **Don't** load all alerts at once; paginate instead
- **Don't** rebuild entire widget trees unnecessarily (use Consumer wisely)
- **Don't** make synchronous API calls on the main thread
- **Don't** hold references to disposed providers
- **Don't** use FutureBuilder inside frequently rebuilt widgets

### Testing & Deployment
- **Don't** merge unfinished features to main
- **Don't** skip testing on target devices before release
- **Don't** deploy without checking error logs
- **Don't** modify production data without backup
- **Don't** ignore type warnings or analyzer issues

### Documentation
- **Don't** leave TODO comments without context
- **Don't** forget to update this guide when adding new patterns
- **Don't** assume future developers know your naming conventions
- **Don't** commit work-in-progress without noting status

---

## 📋 Current Architecture

### Providers (`lib/providers/`)
- **AuthProvider** - Firebase authentication & user roles
- **AlertProvider** - Alert state and triggers
- **AQIProvider** - Air quality data management
- **FloodProvider** - Flood alert data
- **ReportProvider** - User reports on hazards

### Services (`lib/services/`)
- **FirebaseAuthService** - Firebase Auth wrapper
- **OpenWeatherWeatherSource** - Real-time weather data

### Screens (`lib/screens/`)
- Login/Signup flows with Firebase
- Home dashboard with alerts
- Admin panels for content & reports
- User profile & settings

### Models (`lib/models/`)
- UserModel, AlertModel, ReportModel, etc.
- Keep models serializable to JSON

---

## 🚀 Common Tasks

### Adding a New Alert Type
1. Create model in `lib/models/`
2. Create provider in `lib/providers/`
3. Create screen in `lib/screens/`
4. Add route to `lib/main.dart`
5. Test on both Android and iOS

### Integrating a New Data Source
1. Create service in `lib/services/`
2. Implement with proper error handling
3. Integrate into relevant provider
4. Add to API configuration
5. Test with real data before committing

### Adding Admin Features
1. Check user role in AuthProvider
2. Create admin screen in `lib/screens/admin_*`
3. Protect routes with role checks
4. Test with admin account
5. Document new permissions

---

## 🔧 Setup for New Developers

```bash
# Clone and setup
git clone <repo>
cd App/ecoalert
flutter pub get

# Configure Firebase
# 1. Download google-services.json from Firebase Console
# 2. Place in android/app/
# 3. Ensure ios/Podfile is configured

# Run app
flutter run -d <device-id>

# Run tests
flutter test
```

---

## 📞 Contact & Questions
For unclear requirements or architectural decisions, check recent commits or ask the team lead.

---

**Last Updated:** 2026-05-19
