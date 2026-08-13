import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/expense.dart';

class AIService {
  static const String apiKey =
    String.fromEnvironment('GEMINI_API_KEY');

  Future<String> getAdvice({
    required double budget,
    required double totalExpense,
    required List<Expense> expenses,
  }) async {
    final double remaining = budget - totalExpense;

    // Calculate spending by category
    final Map<String, double> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    String categoryText = "";

    if (categoryTotals.isEmpty) {
      categoryText = "No expenses have been recorded yet.";
    } else {
      categoryTotals.forEach((category, amount) {
        categoryText +=
            "$category: Rs. ${amount.toStringAsFixed(0)}\n";
      });
    }

    // Expense details
    String expenseText = "";

    if (expenses.isEmpty) {
      expenseText = "No expenses recorded.";
    } else {
      for (final expense in expenses.take(10)) {
        expenseText +=
            "${expense.title}: Rs. ${expense.amount.toStringAsFixed(0)} "
            "(${expense.category})\n";
      }
    }

    final prompt = """
You are a personal budgeting advisor for a Pakistani university student.

Analyze the student's ACTUAL financial data.

MONTHLY BUDGET:
Rs. ${budget.toStringAsFixed(0)}

TOTAL SPENT:
Rs. ${totalExpense.toStringAsFixed(0)}

REMAINING BUDGET:
Rs. ${remaining.toStringAsFixed(0)}

NUMBER OF EXPENSES:
${expenses.length}

SPENDING BY CATEGORY:
$categoryText

RECENT EXPENSES:
$expenseText

Give exactly 5 practical and concise budgeting tips.

Each tip should be 1–2 complete sentences.
Make sure every sentence is completed.
Do not stop mid-sentence.
Keep the total response reasonably concise.

IMPORTANT:
- Base every tip on the student's actual numbers and expenses.
- Mention specific categories or amounts when useful.
- Clearly point out overspending if it exists.
- If the student is within budget, explain how to stay within budget.
- Consider Pakistani university student expenses.
- Do not give generic advice unrelated to the provided data.
- Keep every tip on a separate line.
- Do not use markdown headings.
""";

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/interactions?key=$apiKey",
    );

    final body = {
      "model": "models/gemini-3-flash-preview",
      "input": prompt,
      "generation_config": {
        "temperature": 1,
        "max_output_tokens": 6000,
        "top_p": 0.95,
        "thinking_level": "low",
      },
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return "API Error (${response.statusCode})\n${response.body}";
      }

      final data = jsonDecode(response.body);

      final steps = data["steps"];

      if (steps is List) {
        for (final step in steps.reversed) {
          if (step["type"] == "model_output") {
            final content = step["content"];

            if (content is List) {
              for (final item in content) {
                if (item["type"] == "text" &&
                    item["text"] != null) {
                  return item["text"].toString().trim();
                }
              }
            }
          }
        }
      }

      return "Gemini did not return any advice.";
    } catch (e) {
      return "Unable to get AI advice.\n$e";
    }
  }
}