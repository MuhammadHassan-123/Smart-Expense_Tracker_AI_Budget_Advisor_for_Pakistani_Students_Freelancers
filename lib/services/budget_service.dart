import 'package:shared_preferences/shared_preferences.dart';

class BudgetService {
  static const String _budgetKey = 'monthly_budget';

  Future<void> saveBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_budgetKey, amount);
  }

  Future<double> getBudget() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getDouble(_budgetKey) ?? 0;
  }
}