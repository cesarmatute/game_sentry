/// Utility functions for number parsing and validation
class NumberUtils {
  /// Parses a string to an integer with error handling
  ///
  /// Returns the parsed integer if successful, or null if parsing fails
  static int? parseInt(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    try {
      return int.parse(value);
    } catch (e) {
      return null;
    }
  }

  /// Parses a string to an integer with a default value
  ///
  /// Returns the parsed integer if successful, or [defaultValue] if parsing fails
  static int parseIntWithDefault(String? value, {int defaultValue = 0}) {
    if (value == null || value.isEmpty) {
      return defaultValue;
    }
    
    try {
      return int.parse(value);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Validates if a string can be parsed to an integer
  ///
  /// Returns true if the string can be parsed to an integer, false otherwise
  static bool isValidInt(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }
    
    try {
      int.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }
}