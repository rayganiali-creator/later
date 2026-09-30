# Flutter's own rules are applied automatically by the Flutter Gradle plugin.

# Keep stack traces readable in store crash reports.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Poolakey (Cafe Bazaar billing) ships its own consumer rules; nothing extra needed.
# flutter_local_notifications uses Gson with generics; its consumer rules cover it.
