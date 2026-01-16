class Expense {
  final String id;
  final double amount;
  final String category;
  final String description;
  final String merchant;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    this.merchant = '',
    required this.date,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to parse date from various formats
      DateTime parseDate(dynamic dateValue) {
        if (dateValue == null) return DateTime.now();
        
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is Map) {
          // Firestore Timestamp format: {_seconds: xxx, _nanoseconds: xxx}
          final seconds = dateValue['_seconds'] ?? dateValue['seconds'];
          if (seconds != null) {
            return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
        
        return DateTime.now();
      }
      
      return Expense(
        id: json['_id'] ?? json['id'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        category: json['category'] ?? 'others',
        description: json['description'] ?? '',
        merchant: json['merchant'] ?? '',
        date: parseDate(json['date']),
        createdAt: parseDate(json['createdAt']),
      );
    } catch (e, stackTrace) {
      print('[Expense] Error parsing expense: $e');
      print('[Expense] JSON: $json');
      print('[Expense] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'description': description,
      'merchant': merchant,
      'date': date.toIso8601String(),
    };
  }

  // Get emoji icon for category
  String get categoryIcon {
    const icons = {
      'clothes': '👕',
      'drinks': '🍺',
      'education': '📚',
      'food': '🍔',
      'fuel': '⛽',
      'fun': '🎮',
      'health': '💊',
      'hotel': '🏨',
      'personal': '👤',
      'pets': '🐾',
      'restaurants': '🍽️',
      'tips': '💰',
      'transport': '🚗',
      'others': '📦',
    };
    return icons[category.toLowerCase()] ?? '📦';
  }

  // Get display name for category
  String get categoryDisplayName {
    return category.substring(0, 1).toUpperCase() + category.substring(1);
  }
}
