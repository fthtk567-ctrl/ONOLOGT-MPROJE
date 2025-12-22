# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Play Core (deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Supabase
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Google Maps (eğer kullanıyorsanız)
-keep class com.google.android.gms.maps.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Prevent obfuscation of model classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
