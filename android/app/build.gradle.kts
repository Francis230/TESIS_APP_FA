plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter siempre debe ir después de Android y Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // ✅ Namespace obligatorio en AGP 8+
    namespace = "com.tesis.appmovilfaj"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.tesis.appmovilfaj"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true // 🔧 Recomendado para evitar problemas de métodos 64k
    }

    compileOptions {
        // ✅ Compatibilidad Java 1.8
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true // 👈 aquí
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    buildTypes {
        getByName("release") {
            // 🔧 Para que flutter build funcione incluso sin keystore configurado
            signingConfig = signingConfigs.getByName("debug")
            // isMinifyEnabled = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // 👈 aquí
}

flutter {
    source = "../.."
}