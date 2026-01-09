plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.electroride"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Matches your local_notifications requirement

    compileOptions {
        // Required for flutter_local_notifications (Java 8+ support)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.electroride"
        // You can update these values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Using debug keys for the release build to prevent "SigningConfig not found"
            // This allows you to run 'flutter build apk --release' for testing on your phone.
            val debugConfig = getByName("debug")
            storeFile = debugConfig.storeFile
            storePassword = debugConfig.storePassword
            keyAlias = debugConfig.keyAlias
            keyPassword = debugConfig.keyPassword
        }
    }

    buildTypes {
        release {
            // Tells Gradle to use the signing configuration defined above
            signingConfig = signingConfigs.getByName("release")


            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required library for desugaring modern Java features (java.time, etc.)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}