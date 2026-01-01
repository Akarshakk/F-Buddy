enum DebtType {
  theyOweMe,
  iOwe,
}

class Debt {
  final String id;
  final DebtType type;
  final double amount;
  final String personName;
  final String description;
  final DateTime dueDate;
  final bool isSettled;
  final DateTime? settledDate;
  final bool reminderSent;
  final DateTime createdAt;

  Debt({
    required this.id,
    required this.type,
    required this.amount,
    required this.personName,
    this.description = '',
    required this.dueDate,
    this.isSettled = false,
    this.settledDate,
    this.reminderSent = false,
    required this.createdAt,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] == 'they_owe_me' ? DebtType.theyOweMe : DebtType.iOwe,
      amount: (json['amount'] ?? 0).toDouble(),
      personName: json['personName'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      isSettled: json['isSettled'] ?? false,
      settledDate: json['settledDate'] != null
          ? DateTime.parse(json['settledDate'])
          : null,
      reminderSent: json['reminderSent'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == DebtType.theyOweMe ? 'they_owe_me' : 'i_owe',
      'amount': amount,
      'personName': personName,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  // Check if due date is today
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  // Check if overdue
  bool get isOverdue {
    if (isSettled) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  // Get display text for type
  String get typeDisplayText {
    return type == DebtType.theyOweMe ? 'They Owe Me' : 'I Owe';
  }

  // Get icon for type
  String get typeIcon {
    return type == DebtType.theyOweMe ? '💰' : '💸';
  }

  // Days until due (negative if overdue)
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  // Copy with method
  Debt copyWith({
    String? id,
    DebtType? type,
    double? amount,
    String? personName,
    String? description,
    DateTime? dueDate,
    bool? isSettled,
    DateTime? settledDate,
    bool? reminderSent,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      personName: personName ?? this.personName,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      settledDate: settledDate ?? this.settledDate,
      reminderSent: reminderSent ?? this.reminderSent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DebtSummary {
  final double theyOweMe;
  final double iOwe;
  final double netBalance;

  DebtSummary({
    required this.theyOweMe,
    required this.iOwe,
    required this.netBalance,
  });

  factory DebtSummary.fromJson(Map<String, dynamic> json) {
    return DebtSummary(
      theyOweMe: (json['theyOweMe'] ?? 0).toDouble(),
      iOwe: (json['iOwe'] ?? 0).toDouble(),
      netBalance: (json['netBalance'] ?? 0).toDouble(),
    );
  }
}
