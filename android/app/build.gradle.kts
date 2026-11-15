plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.avoera.avoera_pos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.avoera.avoera_pos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("rilisTetap") {
            // Keystore rilis TETAP dari Codemagic (diunggah sekali ke
            // Code signing identities, referensi avoera_release).
            // Codemagic menyediakan jalurnya lewat variabel CM_*.
            // Tanpa ini APK memakai kunci debug mesin build yang
            // BERGANTI tiap build -> tiap update wajib uninstall.
            val jalur = System.getenv("CM_KEYSTORE_PATH")
            if (jalur != null) {
                storeFile = file(jalur)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Di Codemagic: tanda tangan rilis tetap. Di luar itu
            // (build lokal): tetap kunci debug supaya bisa dipasang.
            signingConfig = if (System.getenv("CM_KEYSTORE_PATH") != null) {
                signingConfigs.getByName("rilisTetap")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
