allprojects {
    repositories {
        google()
        mavenCentral()
    }
}



rootProject.layout.buildDirectory.set(layout.buildDirectory.dir("build"))

subprojects {


    repositories {
        google()
        mavenCentral()
    }
}




tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}









