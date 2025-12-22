## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

## Supabase
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }

## Geolocator
-keep class com.baseflow.geolocator.** { *; }

## Firebase (FCM notifications)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

## Audioplayers
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

## Google Maps
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.maps.**

## Play Core (In-app updates)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

## Excel export library
-keep class org.apache.poi.** { *; }
-dontwarn org.apache.poi.**
