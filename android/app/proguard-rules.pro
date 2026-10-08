# StationX R8 / ProGuard rules for release builds.
# Flutter's Gradle plugin adds the Flutter engine rules itself. Add keep rules below ONLY if a
# release build is found to break at runtime (and document why in docs/RELEASE.md).

# Isar is used through generated Dart code + a native library (JNI); the Java side only holds
# the native-library loader and JNI-called classes.
-keep class dev.isar.isar_flutter_libs.** { *; }
-keep class io.isar.** { *; }

# Health Connect (health plugin) and androidx.health.connect client use reflection-free Kotlin,
# but keep the plugin's classes so method-channel handlers are not stripped.
-keep class cachet.plugins.health.** { *; }

# Play Core deferred components are referenced by the Flutter engine but not bundled.
-dontwarn com.google.android.play.core.**
