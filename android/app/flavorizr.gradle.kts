import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("mock") {
            dimension = "flavor-type"
            applicationId = "com.example.gestor_tareas_personales.mock"
            resValue(type = "string", name = "app_name", value = "[MOCK] Gestor de Tareas")
        }
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.example.gestor_tareas_personales.dev"
            resValue(type = "string", name = "app_name", value = "[DEV] Gestor de Tareas")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.example.gestor_tareas_personales"
            resValue(type = "string", name = "app_name", value = "Gestor de Tareas")
        }
    }

    buildFeatures.resValues = true
}