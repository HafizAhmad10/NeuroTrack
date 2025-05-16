plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin must be applied after Android and Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kafkabytes.neurotrack"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    aaptOptions {
        noCompress += listOf("tflite", "lite")
    }

    defaultConfig {
        applicationId = "com.kafkabytes.neurotrack"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64", "x86")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    implementation("org.tensorflow:tensorflow-lite:2.11.0")
}

flutter {
    source = "../.."
}
