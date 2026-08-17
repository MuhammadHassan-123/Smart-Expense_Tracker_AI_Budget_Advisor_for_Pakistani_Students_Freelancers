enum BudgetPeriod { monthly, yearly }

class BudgetPlan {
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final List<double> monthlyAllocations;
  final bool carryForward;

  const BudgetPlan({
    required this.amount,
    required this.period,
    required this.startDate,
    this.monthlyAllocations = const [],
    this.carryForward = false,
  });

  List<double> get normalizedAllocations {
    if (period == BudgetPeriod.monthly) return [amount];
    if (monthlyAllocations.length == 12 &&
        monthlyAllocations.fold<double>(0, (s, v) => s + v) > 0) {
      return List<double>.from(monthlyAllocations);
    }
    final each = amount / 12;
    return List<double>.filled(12, each);
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'period': period.name,
        'startDate': startDate.toIso8601String(),
        'monthlyAllocations': normalizedAllocations,
        'carryForward': carryForward,
      };

  factory BudgetPlan.fromMap(Map<String, dynamic> map) {
    final rawAllocations = map['monthlyAllocations'];
    final allocations = rawAllocations is List
        ? rawAllocations
            .map((e) => (e as num?)?.toDouble() ?? 0)
            .toList()
        : <double>[];

    return BudgetPlan(
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      period: BudgetPeriod.values.firstWhere(
        (value) => value.name == map['period']?.toString(),
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.tryParse(map['startDate']?.toString() ?? '') ?? DateTime.now(),
      monthlyAllocations: allocations,
      carryForward: map['carryForward'] == true,
    );
  }

  String get periodLabel => period == BudgetPeriod.monthly ? 'Monthly' : 'Yearly';
}

class BudgetPeriodInfo {
  final DateTime start;
  final DateTime end;

  const BudgetPeriodInfo({required this.start, required this.end});

  int get totalDays => end.difference(start).inDays + 1;

  int get daysRemaining {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    if (day.isBefore(start)) return totalDays;
    if (day.isAfter(end)) return 0;
    return end.difference(day).inDays + 1;
  }

  int get daysElapsed => totalDays - daysRemaining;
}
