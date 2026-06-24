import 'package:intl/intl.dart';
import 'dart:math' as dart_math;

/// Utility class for date and time formatting
class DateTimeUtils {
  /// Format date as 'MMM dd, yyyy' (e.g., Jan 09, 2026)
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  /// Format date and time as 'MMM dd, yyyy hh:mm a'
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }
  
  /// Format time as 'hh:mm a' (e.g., 02:30 PM)
  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
  
  /// Format date for chart labels (e.g., 'Mon 9')
  static String formatChartDate(DateTime date) {
    return DateFormat('E d').format(date);
  }
  
  /// Get time ago string (e.g., '2 hours ago')
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(dateTime);
    }
  }
  
  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
  
  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  /// Get list of dates for the last N days
  static List<DateTime> getLastNDays(int n) {
    final now = DateTime.now();
    return List.generate(n, (index) {
      return startOfDay(now.subtract(Duration(days: n - 1 - index)));
    });
  }
}

/// Utility class for number formatting
class NumberUtils {
  /// Format number with commas (e.g., 1,234,567)
  static String formatNumber(num value) {
    return NumberFormat('#,##0').format(value);
  }
  
  /// Format decimal number (e.g., 1,234.56)
  static String formatDecimal(num value, {int decimals = 2}) {
    return NumberFormat('#,##0.${'0' * decimals}').format(value);
  }
  
  /// Format percentage (e.g., 75.5%)
  static String formatPercentage(num value, {int decimals = 1}) {
    return '${formatDecimal(value, decimals: decimals)}%';
  }
  
  /// Format duration in hours and minutes
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
  
  /// Clamp value between min and max
  static num clamp(num value, num min, num max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

/// Utility class for validation
class ValidationUtils {
  /// Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
  
  /// Validate password (min 8 chars, at least one uppercase, one lowercase, one number)
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    
    return hasUppercase && hasLowercase && hasDigit;
  }
  
  /// Validate animal ID (alphanumeric, 4-20 chars)
  static bool isValidAnimalId(String id) {
    final idRegex = RegExp(r'^[a-zA-Z0-9]{4,20}$');
    return idRegex.hasMatch(id);
  }
  
  /// Check if string is empty or null
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }
  
  /// Check if value is within range
  static bool isInRange(num value, num min, num max) {
    return value >= min && value <= max;
  }
}

/// Utility class for data calculations
class CalculationUtils {
  /// Calculate movement score (0-100)
  /// Based on step count and activity duration
  static double calculateMovementScore({
    required int stepCount,
    required double activityHours,
    int maxSteps = 5000,
    double maxHours = 12.0,
  }) {
    final stepScore = (stepCount / maxSteps) * 60;
    final durationScore = (activityHours / maxHours) * 40;
    final totalScore = stepScore + durationScore;
    
    return NumberUtils.clamp(totalScore, 0, 100).toDouble();
  }
  
  /// Calculate lameness risk level based on rule-based system
  /// Returns 0 (Normal), 1 (Mild), 2 (Severe)
  static int calculateLamenessRisk({
    required int stepCount,
    required double activityHours,
    required double restHours,
  }) {
    // Severe lameness indicators
    if (stepCount < 1000 && restHours > 18) {
      return 2; // Severe
    }
    
    // Mild lameness indicators
    if (stepCount < 2000 && activityHours < 5) {
      return 1; // Mild
    }
    
    // Normal
    return 0;
  }
  
  /// Calculate average from list of numbers
  static double calculateAverage(List<num> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }
  
  /// Calculate standard deviation
  static double calculateStandardDeviation(List<num> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = calculateAverage(values);
    final squaredDifferences = values.map((value) {
      final diff = value - mean;
      return diff * diff;
    }).toList();
    
    final variance = calculateAverage(squaredDifferences);
    return dart_math.sqrt(variance);
  }
  
  /// Normalize value to 0-1 range
  static double normalize(num value, num min, num max) {
    if (max == min) return 0.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}

/// Utility class for color operations
class ColorUtils {
  /// Get color based on lameness severity
  static String getLamenessSeverityColor(String severity) {
    switch (severity) {
      case 'Normal':
        return '#4CAF50'; // Green
      case 'Mild Lameness':
        return '#FFB74D'; // Orange
      case 'Severe Lameness':
        return '#E57373'; // Red
      default:
        return '#9E9E9E'; // Gray
    }
  }
  
  /// Get color based on health status
  static String getHealthStatusColor(String status) {
    switch (status) {
      case 'Healthy':
        return '#4CAF50'; // Green
      case 'Under Observation':
        return '#2196F3'; // Blue
      case 'Sick':
        return '#FF9800'; // Orange
      case 'Critical':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Gray
    }
  }
  
  /// Get color based on movement score (0-100)
  static String getMovementScoreColor(double score) {
    if (score >= 70) return '#4CAF50'; // Green
    if (score >= 40) return '#FFB74D'; // Orange
    return '#E57373'; // Red
  }
}

/// Utility class for string operations
class StringUtils {
  /// Capitalize first letter of each word
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  /// Generate random ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
