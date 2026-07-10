allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    // flutter_google_places_sdk_android 0.2.2 declara Places 5.1.1 pero su
    // Kotlin usa la API 3.x (retirada en la 4.0) y no compila. Se fuerza la
    // última 3.x, que soporta la Places API nueva (useNewApi) desde la 3.3.0.
    configurations.all {
        resolutionStrategy {
            force("com.google.android.libraries.places:places:3.5.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
