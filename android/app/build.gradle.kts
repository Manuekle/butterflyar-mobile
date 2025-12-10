plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// ⭐ CONFIGURACIÓN DE FIRMA PARA RELEASE
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.butterflyar"
    compileSdk = 36  // Requerido por plugins (camera, gal, etc.)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.butterflyar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ⭐ CONFIGURACIÓN DE FIRMA
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // ⭐ USAR FIRMA DE RELEASE
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false // Desactivar minificación para evitar problemas con ARCore
            isShrinkResources = false // Desactivar shrink de recursos
            
            // ⭐ AÑADIR REGLAS DE PROGUARD
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // ⭐ AÑADIR CONFIGURACIÓN PARA ARCore
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
        pickFirst("**/libarcore_sdk_c.so")
    }

    // ⭐ CONFIGURACIÓN LINT
    lintOptions {
        disable("InvalidPackage")
        isCheckReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}