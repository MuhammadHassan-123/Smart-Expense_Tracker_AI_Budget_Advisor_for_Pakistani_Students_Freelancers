import '../models/expense.dart';

class ReceiptParser {
  static Expense parseReceipt(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // -----------------------------
    // Find amount
    // -----------------------------

    double amount = 0;

    final amountPatterns = [
      RegExp(
        r'(?:grand\s*total|total|amount|net\s*total)'
        r'\s*[:\-]?\s*(?:rs\.?|pkr)?\s*([0-9]+(?:[,.][0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rs\.?|pkr)\s*([0-9]+(?:[,.][0-9]{1,2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in amountPatterns) {
      final matches = pattern.allMatches(text);

      if (matches.isNotEmpty) {
        final value = matches.last.group(1);

        if (value != null) {
          amount = double.tryParse(
                value.replaceAll(',', ''),
              ) ??
              0;
        }

        if (amount > 0) {
          break;
        }
      }
    }

    // -----------------------------
    // Find title / merchant
    // -----------------------------

    String title = "Receipt Expense";

    if (lines.isNotEmpty) {
      title = lines.first;

      // Avoid using a line that is obviously just a number.
      if (double.tryParse(title.replaceAll(',', '')) != null) {
        title = "Receipt Expense";
      }
    }

    // -----------------------------
    // Determine category
    // -----------------------------

    final lowerText = text.toLowerCase();

    String category = "Other";

    if (_containsAny(lowerText, [
      "restaurant",
      "cafe",
      "café",
      "food",
      "burger",
      "pizza",
      "biryani",
      "mcdonald",
      "kfc",
      "coffee",
      "bakery",
      "grocery",
      "mart",
    ])) {
      category = "Food";
    } else if (_containsAny(lowerText, [
      "uber",
      "careem",
      "indrive",
      "rickshaw",
      "metro",
      "bus",
      "transport",
      "fuel",
      "petrol",
    ])) {
      category = "Transport";
    } else if (_containsAny(lowerText, [
      "clothing",
      "shoes",
      "shopping",
      "store",
      "mall",
      "garments",
    ])) {
      category = "Shopping";
    } else if (_containsAny(lowerText, [
      "book",
      "books",
      "stationery",
      "education",
      "university",
      "school",
    ])) {
      category = "Education";
    } else if (_containsAny(lowerText, [
      "medicine",
      "pharmacy",
      "medical",
      "hospital",
      "clinic",
    ])) {
      category = "Medicine";
    } else if (_containsAny(lowerText, [
      "internet",
      "jazz",
      "zong",
      "ufone",
      "telenor",
      "data",
      "mobile",
    ])) {
      category = "Internet";
    }

    return Expense(
      title: title,
      amount: amount,
      category: category,
      date: DateTime.now(),
    );
  }

  static bool _containsAny(
    String text,
    List<String> words,
  ) {
    for (final word in words) {
      if (text.contains(word)) {
        return true;
      }
    }

    return false;
  }
}