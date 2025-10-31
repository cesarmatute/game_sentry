import 'package:game_sentry/game_sentry.dart';

void main() {
  // Example 1: Basic integer parsing with error handling
  String? userInput = "123";
  NumberUtils.parseInt(userInput);
  
  // Example 2: Parsing with a default value
  String? invalidInput = "abc";
  NumberUtils.parseIntWithDefault(invalidInput, defaultValue: 0);
  
  // Example 3: Validating input before parsing
  String? testInput = "456";
  if (NumberUtils.isValidInt(testInput)) {
    int.parse(testInput);
  }
  
  // Testing edge cases
  NumberUtils.parseInt(null);
  NumberUtils.parseInt("");
  NumberUtils.parseInt("   ");
  NumberUtils.parseInt("-42");
  NumberUtils.isValidInt("3.14");
}