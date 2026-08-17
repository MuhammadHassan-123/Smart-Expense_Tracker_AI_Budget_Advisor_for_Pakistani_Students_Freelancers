class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
  });

  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity).toDouble();
  double get progress => targetAmount <= 0 ? 0.0 : (savedAmount / targetAmount).clamp(0, 1).toDouble();

  int get daysRemaining {
    final today = DateTime.now();
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day);
    if (end.isBefore(DateTime(today.year, today.month, today.day))) return 0;
    return end.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  double get suggestedMonthlySaving {
    final months = (daysRemaining / 30.44).ceil().clamp(1, 1200);
    return remaining / months;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'targetDate': targetDate.toIso8601String(),
      };

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
        id: map['id'].toString(),
        name: map['name']?.toString() ?? 'Savings Goal',
        targetAmount: (map['targetAmount'] as num).toDouble(),
        savedAmount: (map['savedAmount'] as num).toDouble(),
        targetDate: DateTime.parse(map['targetDate'].toString()),
      );
}
