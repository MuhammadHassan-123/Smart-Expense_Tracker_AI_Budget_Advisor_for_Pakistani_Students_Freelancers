import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/savings_goal.dart';

class AIService {
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<String> getSummary({
    required String periodLabel,
    required double periodBudget,
    required double spent,
    required double committed,
    required double savedThisPeriod,
    required double available,
    required double savingsReserve,
    required double requiredSavingsThisPeriod,
    required double safeDailySpend,
    required double projectedSpend,
    required int daysRemaining,
    required Map<String, double> futureAllocation,
    required List<SavingsGoal> goals,
    required Map<String, double> spendingByCategory,
  }) async {
    final largestGoal = _largestActiveGoal(goals);
    final goalText = goals.isEmpty
        ? 'No active savings goals.'
        : goals
            .take(4)
            .map(
              (goal) =>
                  '${goal.name}: Rs. ${goal.remaining.toStringAsFixed(0)} remaining, '
                  'target ${goal.targetDate.year}-${goal.targetDate.month.toString().padLeft(2, '0')}-${goal.targetDate.day.toString().padLeft(2, '0')}',
            )
            .join('; ');

    final allocationText = futureAllocation.isEmpty
        ? 'No discretionary amount remains for future allocation.'
        : futureAllocation.entries
            .map(
              (entry) =>
                  '${entry.key}: Rs. ${entry.value.toStringAsFixed(0)}',
            )
            .join(', ');

    final status = projectedSpend > periodBudget
        ? 'at risk of exceeding the period budget'
        : 'on track to stay within the period budget';
    final topCategory = _topCategory(spendingByCategory);

    final prompt = '''
You are the financial summary assistant inside a budgeting app for Pakistani students and freelancers.

Write ONE polished paragraph of exactly 3 complete sentences, roughly 70-110 words.
The paragraph must be useful, specific, easy to read, and end with a complete sentence and a full stop.
Do not use bullets, numbering, headings, greetings, disclaimers, or meta commentary.
Cover the overall budget position, the most important current action, and the savings goal situation when relevant.
Do not repeat every number; use only the most useful figures.
Mention the biggest spending category only when it helps explain the next action.

FINANCIAL SNAPSHOT
Period: $periodLabel
Period budget: Rs. ${periodBudget.toStringAsFixed(0)}
Paid spending: Rs. ${spent.toStringAsFixed(0)}
Upcoming commitments: Rs. ${committed.toStringAsFixed(0)}
Savings already added this period: Rs. ${savedThisPeriod.toStringAsFixed(0)}
Available after spending, commitments and savings added: Rs. ${available.toStringAsFixed(0)}
Required savings still due this period: Rs. ${requiredSavingsThisPeriod.toStringAsFixed(0)}
Savings reserve planned first: Rs. ${savingsReserve.toStringAsFixed(0)}
Days remaining: $daysRemaining
Safe daily future-spend amount: Rs. ${safeDailySpend.toStringAsFixed(0)}
Projected spending by period end at the current pace: Rs. ${projectedSpend.toStringAsFixed(0)}
Status: $status

ACTIVE SAVINGS GOALS
$goalText
${largestGoal == null ? '' : 'Most urgent goal: ${largestGoal.name}, with Rs. ${largestGoal.remaining.toStringAsFixed(0)} still needed.'}

FUTURE ALLOCATION
$allocationText

BIGGEST CURRENT SPENDING CATEGORY
${topCategory == null ? 'None yet.' : '${topCategory.key}: Rs. ${topCategory.value.toStringAsFixed(0)}'}
''';

    if (apiKey.isEmpty) {
      return _localSummary(
        periodBudget: periodBudget,
        spent: spent,
        committed: committed,
        savedThisPeriod: savedThisPeriod,
        available: available,
        savingsReserve: savingsReserve,
        safeDailySpend: safeDailySpend,
        projectedSpend: projectedSpend,
        daysRemaining: daysRemaining,
        goals: goals,
        spendingByCategory: spendingByCategory,
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/interactions?key=$apiKey',
    );

    final body = {
      'model': 'models/gemini-3-flash-preview',
      'input': prompt,
      'generation_config': {
        'temperature': 0.3,
        'max_output_tokens': 700,
        'top_p': 0.9,
        'thinking_level': 'low',
      },
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return _localSummary(
          periodBudget: periodBudget,
          spent: spent,
          committed: committed,
          savedThisPeriod: savedThisPeriod,
          available: available,
          savingsReserve: savingsReserve,
          safeDailySpend: safeDailySpend,
          projectedSpend: projectedSpend,
          daysRemaining: daysRemaining,
          goals: goals,
          spendingByCategory: spendingByCategory,
        );
      }

      final data = jsonDecode(response.body);
      final steps = data['steps'];
      if (steps is List) {
        for (final step in steps.toList().reversed) {
          if (step is! Map || step['type'] != 'model_output') continue;
          final content = step['content'];
          if (content is! List) continue;

          for (final item in content) {
            if (item is! Map || item['type'] != 'text') continue;
            final text = item['text']?.toString().trim() ?? '';
            if (_isUsableSummary(text)) return text;
          }
        }
      }
    } catch (_) {
      // Fall back to a deterministic summary so the screen never shows a
      // truncated, broken, or empty sentence.
    }

    return _localSummary(
      periodBudget: periodBudget,
      spent: spent,
      committed: committed,
      savedThisPeriod: savedThisPeriod,
      available: available,
      savingsReserve: savingsReserve,
      safeDailySpend: safeDailySpend,
      projectedSpend: projectedSpend,
      daysRemaining: daysRemaining,
      goals: goals,
      spendingByCategory: spendingByCategory,
    );
  }

  bool _isUsableSummary(String text) {
    if (text.length < 220 || text.length > 700) return false;
    final sentenceCount = RegExp(r'[.!?]\s+[A-Z]').allMatches(text).length;
    if (sentenceCount < 2) return false;
    return RegExp(r'[.!?]$').hasMatch(text);
  }

  String _localSummary({
    required double periodBudget,
    required double spent,
    required double committed,
    required double savedThisPeriod,
    required double available,
    required double savingsReserve,
    required double safeDailySpend,
    required double projectedSpend,
    required int daysRemaining,
    required List<SavingsGoal> goals,
    required Map<String, double> spendingByCategory,
  }) {
    final overspend = projectedSpend > periodBudget;
    final topGoal = _largestActiveGoal(goals);
    final topCategory = _topCategory(spendingByCategory);
    final availableText = available.toStringAsFixed(0);
    final dailyText = safeDailySpend.toStringAsFixed(0);

    final first = overspend
        ? 'You are spending faster than this period can comfortably support, with a projected total of Rs. ${projectedSpend.toStringAsFixed(0)} against a Rs. ${periodBudget.toStringAsFixed(0)} budget.'
        : 'You remain within the current budget, with Rs. $availableText available after paid spending, upcoming commitments and savings already added.';

    final actionSentence = topCategory == null
        ? (savingsReserve > 0
            ? 'Protect the planned savings reserve of Rs. ${savingsReserve.toStringAsFixed(0)} first, then keep future spending close to Rs. $dailyText per day for the next $daysRemaining days.'
            : 'Keep future spending close to Rs. $dailyText per day for the next $daysRemaining days and avoid unnecessary new commitments.')
        : (savingsReserve > 0
            ? '${topCategory.key} is currently your largest spending category at Rs. ${topCategory.value.toStringAsFixed(0)}; protect the savings reserve first and keep future spending close to Rs. $dailyText per day.'
            : '${topCategory.key} is currently your largest spending category at Rs. ${topCategory.value.toStringAsFixed(0)}; keep future spending close to Rs. $dailyText per day.');

    final goalSentence = topGoal == null
        ? 'No active savings goal is currently competing with the plan, so unused money can remain as a cushion.'
        : 'Your most urgent goal is ${topGoal.name}, with Rs. ${topGoal.remaining.toStringAsFixed(0)} still needed, so its required saving should be protected before optional purchases.';

    return '$first $actionSentence $goalSentence';
  }

  MapEntry<String, double>? _topCategory(Map<String, double> values) {
    if (values.isEmpty) return null;
    MapEntry<String, double>? top;
    for (final entry in values.entries) {
      if (top == null || entry.value > top.value) {
        top = entry;
      }
    }
    return top;
  }

  SavingsGoal? _largestActiveGoal(List<SavingsGoal> goals) {
    final active = goals.where((goal) => goal.remaining > 0).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) {
      final dateCompare = a.targetDate.compareTo(b.targetDate);
      if (dateCompare != 0) return dateCompare;
      return b.remaining.compareTo(a.remaining);
    });
    return active.first;
  }
}
