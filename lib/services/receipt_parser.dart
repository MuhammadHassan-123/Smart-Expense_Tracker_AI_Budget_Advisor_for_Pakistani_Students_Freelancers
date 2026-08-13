import '../models/expense.dart';

class ReceiptParser {
  static Expense parseReceipt(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final lowerText = text.toLowerCase();

    // ---------------------------------------------
    // FIND AMOUNT
    // ---------------------------------------------

    double amount = _findReceiptTotal(lines);

    // ---------------------------------------------
    // FIND MERCHANT
    // ---------------------------------------------

    String title = "Receipt Expense";

    for (final line in lines) {
      if (_isValidMerchant(line)) {
        title = line;
        break;
      }
    }

    // ---------------------------------------------
    // CATEGORY
    // ---------------------------------------------

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
      "cup",
      "deal",
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

  // =================================================
  // RECEIPT TOTAL DETECTION
  // =================================================

  static double _findReceiptTotal(List<String> lines) {
    // -------------------------------------------------
    // STEP 1:
    // Look for explicit total labels.
    // -------------------------------------------------

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      if (line.contains("grand total") ||
          line.contains("net total") ||
          line.contains("amount payable") ||
          line.contains("amount due") ||
          line == "total" ||
          line.startsWith("total ")) {
        final value = _numberFromNearbyLines(lines, i);

        if (value > 0) {
          return value;
        }
      }
    }

    // -------------------------------------------------
    // STEP 2:
    // Look for "total" and amount on same line.
    // -------------------------------------------------

    final totalPattern = RegExp(
      r'(?:grand\s*total|net\s*total|total)'
      r'.*?([0-9]+(?:[,.][0-9]{1,2})?)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = totalPattern.firstMatch(line);

      if (match != null) {
        final value = _parseNumber(match.group(1) ?? '');

        // Don't accept tiny values such as quantities.
        if (value >= 10) {
          return value;
        }
      }
    }

    // -------------------------------------------------
    // STEP 3:
    // Find final standalone amount near bottom.
    //
    // This handles your receipt:
    //
    // 330.44
    // 16.52
    // 347
    //
    // The last standalone amount is the final total.
    // -------------------------------------------------

    final start = lines.length > 12 ? lines.length - 12 : 0;

    final candidates = <double>[];

    for (int i = start; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      // Ignore known non-amount lines.
      if (lower.contains("tax id") ||
          lower.contains("printed") ||
          lower.contains("scan to") ||
          lower.contains("thank you") ||
          lower.contains("prepared by")) {
        continue;
      }

      // We specifically prefer lines containing ONLY a number.
      if (RegExp(
        r'^[0-9]+(?:[,.][0-9]{1,2})?$',
      ).hasMatch(line)) {
        final value = _parseNumber(line);

        if (value > 0) {
          candidates.add(value);
        }
      }
    }

    if (candidates.isNotEmpty) {
      return candidates.last;
    }

    // -------------------------------------------------
    // STEP 4:
    // Last fallback: find monetary-looking numbers.
    // -------------------------------------------------

    final fallbackCandidates = <double>[];

    for (int i = start; i < lines.length; i++) {
      final matches = RegExp(
        r'(?<!\d)([0-9]+(?:[,.][0-9]{1,2})?)(?!\d)',
      ).allMatches(lines[i]);

      for (final match in matches) {
        final value = _parseNumber(match.group(1) ?? '');

        if (value >= 10) {
          fallbackCandidates.add(value);
        }
      }
    }

    if (fallbackCandidates.isNotEmpty) {
      return fallbackCandidates.last;
    }

    return 0;
  }

  // =================================================
  // GET NUMBER FROM FOLLOWING LINES
  // =================================================

  static double _numberFromNearbyLines(
    List<String> lines,
    int index,
  ) {
    // Check same line first.
    final sameLine = _extractNumber(lines[index]);

    if (sameLine > 0) {
      return sameLine;
    }

    // Check next 2 lines.
    for (int i = index + 1;
        i < lines.length && i <= index + 2;
        i++) {
      final value = _extractNumber(lines[i]);

      if (value > 0) {
        return value;
      }
    }

    return 0;
  }

  // =================================================
  // EXTRACT NUMBER
  // =================================================

  static double _extractNumber(String line) {
    final match = RegExp(
      r'(?<!\d)([0-9]+(?:[,.][0-9]{1,2})?)(?!\d)',
    ).firstMatch(line);

    if (match == null) {
      return 0;
    }

    return _parseNumber(match.group(1) ?? '');
  }

  // =================================================
  // NUMBER PARSER
  // =================================================

  static double _parseNumber(String value) {
    String cleaned = value.trim();

    // OCR sometimes reads:
    // 26,09 instead of 26.09
    if (cleaned.contains(',') && !cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '.');
    } else {
      // Example:
      // 1,250.50 -> 1250.50
      cleaned = cleaned.replaceAll(',', '');
    }

    return double.tryParse(cleaned) ?? 0;
  }

  // =================================================
  // MERCHANT
  // =================================================

  static bool _isValidMerchant(String line) {
    final lower = line.toLowerCase();

    if (line.length < 3) return false;

    if (RegExp(r'^[0-9\s.,:/\-]+$').hasMatch(line)) {
      return false;
    }

    if (lower.contains("order")) return false;
    if (lower.contains("customer")) return false;
    if (lower.contains("cashier")) return false;
    if (lower.contains("payment")) return false;
    if (lower.contains("printed")) return false;
    if (lower.contains("thank you")) return false;
    if (lower.contains("scan to")) return false;
    if (lower.contains("rate amount")) return false;
    if (lower.contains("items")) return false;

    return true;
  }

  // =================================================
  // CATEGORY KEYWORDS
  // =================================================

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