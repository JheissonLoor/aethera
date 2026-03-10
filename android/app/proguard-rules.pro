# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase Core + Auth
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Firestore — keep model fields for reflection
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName *;
}
-keep class com.google.firestore.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# Firebase Database (Realtime DB)
-keep class com.google.firebase.database.** { *; }

# Kotlin coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Gson / JSON serialization (used by some Firebase internals)
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Timezone (used by flutter_local_notifications)
-keep class org.threeten.bp.** { *; }
-dontwarn org.threeten.bp.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Suppress common warnings
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
