allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val projectPath = project.projectDir.absolutePath
    val rootPath = rootProject.projectDir.absolutePath
    val isDifferentDrive = projectPath.length > 1 && rootPath.length > 1 && projectPath[0] != rootPath[0]
    
    if (isDifferentDrive) {
        // If the plugin is on a different drive (e.g. C: pub cache), use a build directory on that same drive
        // to prevent the Kotlin "this and base files have different roots" exception.
        val tmpDir = java.io.File(System.getProperty("java.io.tmpdir"), "flutter_builds/${rootProject.name}/${project.name}")
        project.layout.buildDirectory.set(tmpDir)
    } else {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                android.namespace = "com.example.${project.name.replace("-", "_")}"
            }
            project.dependencies.add("compileOnly", "androidx.concurrent:concurrent-futures:1.2.0")
            project.dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
