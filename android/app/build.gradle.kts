plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "top.talyra42.verifin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications 需要 core library desugaring 支持 java.time。
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "top.talyra42.verifin"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // local_auth 要求 minSdk >= 23；取二者较大值，不降低 Flutter 默认值。
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("verifinRelease") {
            storeFile = file("verifin-release.jks")
            storePassword = "verifin-release"
            keyAlias = "verifin"
            keyPassword = "verifin-release"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("verifinRelease")
            // 追加本项目的 R8 规则（ML Kit 未引入脚本的缺类豁免）。
            proguardFiles("proguard-rules.pro")
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

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    // 备份目录 SAF 读写（DocumentFile 树操作）。
    implementation("androidx.documentfile:documentfile:1.0.1")
    // flutter_local_notifications 定时通知所需的 desugaring 运行库。
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // 截图识账的中文离线识别库：google_mlkit_text_recognition 插件对各脚本库只
    // compileOnly，使用方必须显式引入所需脚本，否则 release 构建 R8 报缺类。
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
}
