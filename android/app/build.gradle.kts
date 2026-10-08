import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: create android/key.properties (gitignored — NEVER commit it or the
// keystore). See docs/RELEASE.md. Without it, ANY release build (APK or App Bundle) is
// refused: a release artifact is never signed with the debug key. Debug builds are unaffected.
val keystoreProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "dev.mahdi_ramadhan.stationx"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.mahdi_ramadhan.stationx"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Health Connect (health plugin) requires API 26+.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!keystoreProps.isEmpty) {
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // R8 shrinking is OPT-IN (`flutter build apk --release -Pstationx.minify=true`): the
            // minified build compiles, but could not be run on a device here, so it is off until
            // Isar / Health Connect / sync are verified on a minified release. See docs/RELEASE.md.
            val minify = project.findProperty("stationx.minify") == "true"
            isMinifyEnabled = minify
            isShrinkResources = minify
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // No debug-key fallback: building a release without key.properties fails (see the
            // taskGraph check below) instead of producing a debug-signed "release".
            if (!keystoreProps.isEmpty) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

// Never produce a release APK/AAB signed with the debug key.
gradle.taskGraph.whenReady {
    val releaseTasks = listOf(":app:assembleRelease", ":app:bundleRelease", ":app:packageRelease", ":app:validateSigningRelease")
    if (releaseTasks.any { hasTask(it) } && keystoreProps.isEmpty) {
        throw GradleException("android/key.properties is missing: refusing to build a release APK/App Bundle (it would be signed with the debug key). Create an upload keystore and key.properties first - see docs/RELEASE.md section 2.")
    }
}
