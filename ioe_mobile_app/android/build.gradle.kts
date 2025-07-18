plugins {
    id("com.android.application") version "8.5.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    // Do not change the flutter-gradle-plugin version
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(layout.buildDirectory.dir("build"))

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}