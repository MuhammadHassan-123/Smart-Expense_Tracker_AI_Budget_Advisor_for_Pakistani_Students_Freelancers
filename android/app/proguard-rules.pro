# Keep Google ML Kit Text Recognition classes
-keep class com.google.mlkit.vision.text.** { *; }

# Keep ML Kit common classes
-keep class com.google.mlkit.common.** { *; }

# Keep Flutter ML Kit plugin
-keep class com.google_mlkit_text_recognition.** { *; }

# Suppress missing optional ML Kit language classes
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**