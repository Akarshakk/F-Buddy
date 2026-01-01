class Income {
  final String id;
  final double amount;
  final String description;
  final String source;
  final int month;
  final int year;
  final DateTime date;
  final DateTime createdAt;

  Income({
    required this.id,
    required this.amount,
    required this.description,
    required this.source,
    required this.month,
    required this.year,
    required this.date,
    required this.createdAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['_id'] ?? json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? 'Monthly Income',
      source: json['source'] ?? 'pocket_money',
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
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
      'description': description,
      'source': source,
      'month': month,
      'year': year,
      'date': date.toIso8601String(),
    };
  }

  // Get display name for source
  String get sourceDisplayName {
    const names = {
      'pocket_money': 'Pocket Money',
      'salary': 'Salary',
      'freelance': 'Freelance',
      'gift': 'Gift',
      'scholarship': 'Scholarship',
      'other': 'Other',
    };
    return names[source] ?? 'Other';
  }
}
