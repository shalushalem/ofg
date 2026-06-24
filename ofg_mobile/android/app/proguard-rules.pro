# ProGuard rules for OFG Connects

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Riverpod
-keep class dev.rnett.** { *; }

# video_player
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# http
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep all model classes
-keep class ** { *; }
-keepattributes Signature
-keepattributes *Annotation*
