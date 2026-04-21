import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 读取 android/key.properties（不存在则保持为空，release 回退 debug 签名）
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists() &&
        keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.anlife.howtocook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.anlife.howtocook"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            // Debug 版本：支持所有架构（包括模拟器）
            ndk {
                abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86"))
            }
        }

        release {
            // 有 key.properties 时用正式签名，否则回退 debug（本地开发兜底）
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("⚠️  android/key.properties 不存在，release 将使用 debug 签名——仅供本地调试，不可分发！")
                signingConfigs.getByName("debug")
            }

            // Release 版本：只支持手机 ARM 架构，减少体积
            ndk {
                abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
            }

            // 启用代码压缩和资源优化
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // 自定义APK文件名 - 使用正确的语法
    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            output.outputFileName = if (variant.buildType.name == "release") {
                "howtocook.apk"
            } else {
                "howtocook_debug.apk"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
