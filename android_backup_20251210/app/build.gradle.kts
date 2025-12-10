import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
}

android {
    namespace = "com.example.lottogenerator_v4"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.lottogenerator_v4"
        minSdk = 21            // <<< WICHTIG für audioplayers
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
}

