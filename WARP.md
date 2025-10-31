# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Game Sentry is a Flutter application for tracking and managing gaming activities for families. It allows parents to create profiles for their kids, set gaming time limits, and monitor gaming sessions. The app uses Appwrite as a backend service for authentication and data storage.

## Key Commands

### Development Commands
```powershell
# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific platform
flutter run -d windows
flutter run -d chrome

# Build for production
flutter build windows
flutter build web

# Clean project
flutter clean
```

### Testing Commands
```powershell
# Run all tests
flutter test

# Run specific test file
flutter test test/number_utils_test.dart

# Run tests with coverage
flutter test --coverage

# Run widget tests specifically
flutter test test/widget_test.dart
```

### Analysis and Linting
```powershell
# Analyze code for issues
flutter analyze

# Format code
dart format lib/ test/

# Check for outdated dependencies
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

## Architecture Overview

### Project Structure
- **Feature-based architecture**: Code is organized by features (auth, kids, parents, settings, etc.)
- **Repository pattern**: Data layer separated from presentation layer
- **Riverpod for state management**: Provider-based dependency injection and state management
- **Clean architecture principles**: Clear separation between data, presentation, and domain layers

### Key Directories
```
lib/src/
├── core/                    # Shared application core
│   ├── appwrite_client.dart # Appwrite backend configuration
│   └── providers.dart       # Global providers setup
├── features/                # Feature modules
│   ├── auth/               # Authentication (Google OAuth via Appwrite)
│   ├── kids/               # Kids profile management
│   ├── parents/            # Parent profile management  
│   ├── home/               # Home screen and navigation
│   ├── profile/            # User profile management
│   └── settings/           # App settings and themes
└── utils/                  # Shared utilities
    ├── number_utils.dart   # Integer parsing with error handling
    └── dialog_utils.dart   # UI dialog utilities
```

### Core Technologies
- **Flutter SDK**: ^3.8.1
- **Appwrite**: Backend-as-a-Service for auth and database
- **Riverpod**: State management and dependency injection
- **Equatable**: Value equality for models
- **SharedPreferences**: Local storage
- **HTTP**: API calls

### State Management Pattern
The app uses Riverpod with a specific pattern:
- **Providers** in `lib/src/core/providers.dart` for dependency injection
- **StateNotifier** pattern for complex state (see `AuthNotifier`)
- **Repository providers** for data access layer
- **Consumer widgets** for UI state consumption

### Data Models
Models use **Equatable** for value equality and include:
- **Parent**: User profile with kids list and preferences
- **Kid**: Child profile with gaming time limits and restrictions
- **AuthState**: Authentication status and user information

All models have `fromDocument()` factory constructors for Appwrite integration.

### Authentication Flow
1. Google OAuth through Appwrite
2. Auto-creation of Parent document if doesn't exist  
3. State synchronization with retry logic for connection issues
4. User preferences stored in Appwrite user.prefs

### Testing Approach
- **Unit tests** for utilities (see `number_utils_test.dart`)
- **Widget tests** for UI components
- **Group-based test organization** with descriptive test names
- Focus on edge cases and error handling

## Important Implementation Details

### Error Handling
- Repository methods handle Appwrite exceptions gracefully
- Number utilities return null/defaults instead of throwing
- Auth state includes retry logic for connection issues

### Asset Management  
- Images stored in `assets/images/`
- Custom Poppins font family configured
- Material3 theming with dark/light mode support

### Backend Integration
- Appwrite endpoint: `https://nyc.cloud.appwrite.io/v1`
- Project ID: `68ac6b7600141d9fe1d9`
- OAuth provider: Google
- Collections: parents, kids (implied from repository structure)

### Code Quality
- Uses `flutter_lints` for code analysis
- Enforces null safety throughout
- Consistent naming conventions (snake_case for files, camelCase for variables)

## Development Guidelines

### When Adding New Features
1. Create feature directory under `lib/src/features/`
2. Follow data/presentation layer separation
3. Add repository provider to `core/providers.dart`
4. Create corresponding test files
5. Use Equatable for data models
6. Handle Appwrite exceptions appropriately

### When Writing Tests
- Place in `test/` directory mirroring `lib/` structure
- Group tests by functionality
- Test both happy path and error conditions  
- Use descriptive test names

### Common Patterns
- Use `StateNotifier` for complex state management
- Repository pattern for data access
- Factory constructors for model creation from external data
- Provider-based dependency injection
- Consumer widgets for state-dependent UI
