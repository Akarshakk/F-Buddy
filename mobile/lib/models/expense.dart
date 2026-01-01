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
    return Expense(
      id: json['_id'] ?? json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'others',
      description: json['description'] ?? '',
      merchant: json['merchant'] ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
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
