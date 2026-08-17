# Smart Expense Tracker & AI Financial Advisor

A Flutter-based personal finance application designed for students and freelancers, with flexible budgeting, expense tracking, receipt OCR, voice entry, savings goals, analytics, and AI-assisted financial planning.

## Core features

- Monthly and yearly budget plans with a user-defined cycle start date.
- Yearly plans with 12 configurable budget periods and planned-vs-actual tracking.
- Manual, voice, and receipt-based expense entry.
- Fixed/variable and paid/upcoming expense classification.
- Persistent local storage with SharedPreferences for the current prototype.
- Savings goals with target dates, contributions, progress, and required saving pace.
- Future-budget allocation that reserves savings goals before discretionary spending.
- AI financial summary using Gemini, with a concise summary and a future-allocation pie chart.
- Analytics with category spending and yearly period tracking.
- Professional cream/sage finance-oriented interface.

## AI key configuration

The Gemini API key is intentionally **not stored in source code**.

Run locally with:

```powershell
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

Build a release APK with:

```powershell
flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

Never commit the actual key to GitHub.

## Verification

After extracting the project:

```powershell
flutter pub get
flutter analyze
```

Then test on an Android device with the `--dart-define` command above.
