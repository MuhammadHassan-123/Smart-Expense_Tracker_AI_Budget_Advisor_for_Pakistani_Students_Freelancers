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

  /// Number of calendar months available from [referenceDate] through the
  /// target month. The current month is included, so the schedule naturally
  /// rebalances as a user saves more/less and as a new month begins.
  int remainingMonths([DateTime? referenceDate]) {
    final reference = referenceDate ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    if (target.isBefore(today)) return 1;

    final months =
        (target.year - today.year) * 12 +
        (target.month - today.month) +
        1;
    return months.clamp(1, 1200).toInt();
  }

  /// Dynamic monthly contribution required to reach the goal on time.
  /// It is recalculated from the current remaining balance every time, so
  /// contributing above or below the previous pace automatically changes the
  /// future monthly requirement.
  double requiredMonthlySaving([DateTime? referenceDate]) {
    return remaining / remainingMonths(referenceDate);
  }

  double get suggestedMonthlySaving => requiredMonthlySaving();

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
