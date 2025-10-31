# Number Utilities

This package provides utility functions for parsing and validating integers with proper error handling.

## Functions

### `parseInt(String? value)`
Parses a string to an integer with error handling.
- Returns the parsed integer if successful
- Returns `null` if parsing fails or input is null/empty

```dart
int? result = NumberUtils.parseInt("123"); // Returns 123
int? result = NumberUtils.parseInt("abc"); // Returns null
```

### `parseIntWithDefault(String? value, {int defaultValue = 0})`
Parses a string to an integer with a default value.
- Returns the parsed integer if successful
- Returns `defaultValue` if parsing fails or input is null/empty

```dart
int result = NumberUtils.parseIntWithDefault("123"); // Returns 123
int result = NumberUtils.parseIntWithDefault("abc", defaultValue: -1); // Returns -1
```

### `isValidInt(String? value)`
Validates if a string can be parsed to an integer.
- Returns `true` if the string can be parsed to an integer
- Returns `false` otherwise

```dart
bool isValid = NumberUtils.isValidInt("123"); // Returns true
bool isValid = NumberUtils.isValidInt("abc"); // Returns false
```

## Usage Example

```dart
import 'package:game_sentry/src/utils/number_utils.dart';

// Parsing with null checking
String userInput = "123";
int? result = NumberUtils.parseInt(userInput);
if (result != null) {
  print("Parsed value: $result");
} else {
  print("Invalid input");
}

// Using default values
int value = NumberUtils.parseIntWithDefault("abc", defaultValue: 0);
print("Value: $value"); // Prints "Value: 0"

// Validating before parsing
if (NumberUtils.isValidInt("456")) {
  int parsed = int.parse("456");
  print("Valid: $parsed");
}
```