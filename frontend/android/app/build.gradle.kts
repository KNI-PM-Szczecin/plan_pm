import java.util.Properties

plugins {
    id("com.android.application")
    // Bez "kotlin-android": nakłada go Flutter Gradle Plugin (szablon Fluttera 3.44.4).
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.piotrwittig.plan_pm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.toString()?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.piotrwittig.plan_pm"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}

// home_widget 0.10.0 woła Glance już przy starcie (HomeWidgetPreviews w
// onAttachedToEngine), więc wykluczenie glance-appwidget = crash aplikacji.
// Przypinamy 1.2.0 (tę deklaruje plugin): nowsze alpha ciągną
// remote-creation-android, które wymaga AGP 9.1+ i compileSdk 37.
configurations.all {
    resolutionStrategy.force("androidx.glance:glance-appwidget:1.2.0")
    exclude(group = "androidx.compose.remote", module = "remote-creation-android")
}
