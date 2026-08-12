class Budget {
  final String? id;
  final double amount;

  Budget({
    this.id,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String id) {
    return Budget(
      id: id,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}