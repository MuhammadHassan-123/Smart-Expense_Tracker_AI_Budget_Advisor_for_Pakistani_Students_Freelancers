# Smart Expense Tracker – V6

Focus of this revision:
- Clean, cream/sage professional UI hierarchy.
- Savings contributions are handled with explicit validation and error recovery instead of uncaught UI exceptions.
- AI Advisor is a future-budget planning screen, not a historical spending chart.
- Savings reserve is shown first, followed by a single future-allocation legend.
- AI summary is kept concise and the screen avoids duplicate category text.

Before release:
1. flutter pub get
2. flutter analyze
3. flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
4. Test savings contribution and AI allocation.
