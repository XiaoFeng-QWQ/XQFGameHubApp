pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            // 注意：java.util.Properties.load(InputStream) 固定按 ISO-8859-1 解码，
            // 而本项目位于含中文的路径下（…/共享文件1/AndroidApp），
            // 必须显式按 UTF-8 读取，否则 flutter.sdk 会被解码成乱码。
            file("local.properties").reader(Charsets.UTF_8).use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
