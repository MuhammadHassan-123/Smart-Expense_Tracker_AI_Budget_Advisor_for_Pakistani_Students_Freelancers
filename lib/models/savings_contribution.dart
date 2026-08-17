class SavingsContribution {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;

  const SavingsContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory SavingsContribution.fromMap(Map<String, dynamic> map) {
    return SavingsContribution(
      id: map['id']?.toString() ?? '',
      goalId: map['goalId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
