// ============================================
// File: lib/utils/vehicle_validation.dart
// ============================================

class VehicleValidation {
  // Regular expression for Indian vehicle numbers
  // Supports: TN12AB1234, TN-12-AB-1234, TN 12 AB 1234
  static final RegExp _pattern = RegExp(
    r'^[A-Z]{2}[-\s]?[0-9]{1,2}[-\s]?[A-Z]{1,3}[-\s]?[0-9]{1,4}$',
    caseSensitive: false,
  );

  /// Validates vehicle number format
  /// Returns true if valid, false otherwise
  static bool isValid(String vehicleNumber) {
    if (vehicleNumber.isEmpty) {
      return false;
    }

    // Remove extra spaces and convert to uppercase
    String cleaned = vehicleNumber
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toUpperCase();

    return _pattern.hasMatch(cleaned);
  }

  /// Formats vehicle number to standard format: TN-12-AB-1234
  static String format(String vehicleNumber) {
    if (vehicleNumber.isEmpty) {
      return vehicleNumber;
    }

    // Remove all spaces and hyphens
    String cleaned = vehicleNumber
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .toUpperCase();

    if (cleaned.length < 8) {
      return vehicleNumber;
    }

    try {
      // Extract: State (2) + District (1-2) + Letters (1-3) + Numbers (1-4)
      String state = cleaned.substring(0, 2);
      String remaining = cleaned.substring(2);

      // Find where digits end (district number)
      int districtEnd = 0;
      for (int i = 0; i < remaining.length; i++) {
        if (!_isDigit(remaining[i])) {
          districtEnd = i;
          break;
        }
      }

      if (districtEnd == 0) return vehicleNumber;

      String district = remaining.substring(0, districtEnd);
      remaining = remaining.substring(districtEnd);

      // Find where letters end
      int lettersEnd = 0;
      for (int i = 0; i < remaining.length; i++) {
        if (_isDigit(remaining[i])) {
          lettersEnd = i;
          break;
        }
      }

      if (lettersEnd == 0) return vehicleNumber;

      String letters = remaining.substring(0, lettersEnd);
      String numbers = remaining.substring(lettersEnd);

      // Return formatted: TN-12-AB-1234
      return '$state-$district-$letters-$numbers';
    } catch (e) {
      return vehicleNumber;
    }
  }

  /// Returns detailed error message
  static String getErrorMessage() {
    return 'Invalid vehicle number format!\n\n'
        'Valid formats:\n'
        '• TN12AB1234 (without hyphens)\n'
        '• TN-12-AB-1234 (with hyphens)\n'
        '• TN 12 AB 1234 (with spaces)\n'
        '• TN12A1234 (old format)\n'
        '• TN12EV1234 (electric vehicles)\n\n'
        'Example: TN-01-AB-1234\n'
        'State(2) - District(1-2) - Series(1-3) - Number(1-4)';
  }

  /// Returns example for given state code
  static String getExample(String? stateCode) {
    if (stateCode != null && stateCode.length == 2) {
      return '${stateCode.toUpperCase()}-12-AB-1234';
    }
    return 'TN-12-AB-1234';
  }

  /// Checks if vehicle belongs to specific state
  static bool isFromState(String vehicleNumber, String stateCode) {
    if (vehicleNumber.length < 2) {
      return false;
    }

    String vehicleState = vehicleNumber.substring(0, 2).toUpperCase();
    String targetState = stateCode.toUpperCase();

    return vehicleState == targetState;
  }

  /// Extracts state code (first 2 letters)
  static String? getStateCode(String vehicleNumber) {
    if (vehicleNumber.length < 2) {
      return null;
    }

    String cleaned = vehicleNumber
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .toUpperCase();

    return cleaned.substring(0, 2);
  }

  /// Extracts district code
  static String? getDistrictCode(String vehicleNumber) {
    String cleaned = vehicleNumber
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .toUpperCase();

    if (cleaned.length < 4) {
      return null;
    }

    String afterState = cleaned.substring(2);
    String district = '';

    for (int i = 0; i < afterState.length; i++) {
      if (_isDigit(afterState[i])) {
        district += afterState[i];
      } else {
        break;
      }
    }

    return district.isEmpty ? null : district;
  }

  /// Validates and formats in one step
  static String? validateAndFormat(String vehicleNumber) {
    if (!isValid(vehicleNumber)) {
      return null;
    }
    return format(vehicleNumber);
  }

  // Helper: Check if character is digit
  static bool _isDigit(String char) {
    if (char.isEmpty) return false;
    int code = char.codeUnitAt(0);
    return code >= 48 && code <= 57; // '0' to '9'
  }

  // Common state codes
  static const Map<String, String> stateCodes = {
    'TN': 'Tamil Nadu',
    'KA': 'Karnataka',
    'KL': 'Kerala',
    'AP': 'Andhra Pradesh',
    'TS': 'Telangana',
    'MH': 'Maharashtra',
    'DL': 'Delhi',
    'UP': 'Uttar Pradesh',
    'GJ': 'Gujarat',
    'RJ': 'Rajasthan',
    'WB': 'West Bengal',
    'MP': 'Madhya Pradesh',
    'HR': 'Haryana',
    'PB': 'Punjab',
    'OR': 'Odisha',
    'BR': 'Bihar',
    'JH': 'Jharkhand',
    'CG': 'Chhattisgarh',
    'AS': 'Assam',
    'HP': 'Himachal Pradesh',
    'UK': 'Uttarakhand',
    'GA': 'Goa',
  };

  /// Get state name from code
  static String? getStateName(String stateCode) {
    return stateCodes[stateCode.toUpperCase()];
  }
}
