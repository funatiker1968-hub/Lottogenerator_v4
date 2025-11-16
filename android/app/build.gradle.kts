// File: android/app/build.gradle.kts
// Regenerated: 2025-11-16 15:47 MEZ
// Purpose: Saubere Android-App-Konfiguration für Lottogenerator_v4 (Flutter 3.38.x)

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lottogenerator_v4"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.lottogenerator_v4"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // ProGuard / R8 kann später dazukommen, wenn nötig
        }
    }
}

// Flutter-Plugin-Konfiguration: Pfad zum Flutter-Projekt
flutter {
    source = "../.."
}
