# Flutter's own rules are applied automatically by the Flutter Gradle plugin.

# Keep stack traces readable in store crash reports.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Poolakey (Cafe Bazaar billing) ships its own consumer rules; nothing extra needed.
# flutter_local_notifications uses Gson with generics; its consumer rules cover it.

# flutter_local_notifications (Gson reflection on generic types) — needed with R8.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class app.baadan.later.** { *; }
