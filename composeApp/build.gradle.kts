import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.jetbrainsCompose)
    alias(libs.plugins.compose.compiler)
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}

kotlin {
    jvm("desktop")

    sourceSets {
        val desktopMain by getting

        commonMain.dependencies {
            implementation(compose.runtime)
            implementation(compose.foundation)
            implementation(compose.material3)
            implementation(compose.ui)
            implementation(compose.components.resources)
            implementation(compose.components.uiToolingPreview)
            implementation(libs.settings)

            // Navigation and viewmodel lifecycle
            implementation(libs.androidx.lifecycle.viewmodel)
            implementation(libs.androidx.navigation.compose)
            implementation(libs.androidx.lifecycle.runtime.compose)

            implementation(libs.koin.core)

            implementation(libs.kotlinx.datetime)

            implementation(libs.klogging)
        }
        desktopMain.dependencies {
            implementation(compose.desktop.currentOs) {
                exclude("org.jetbrains.compose.material")
            }
            implementation(libs.kotlinx.coroutines.swing)
        }
    }
}

compose.desktop {
    application {
        mainClass = "fr.thomasbernard03.androidtools.MainKt"

        buildTypes {
            release {
                proguard {
                    configurationFiles.from("proguard-rules.pro") // Ajoute un fichier de règles personnalisé si nécessaire
//                    ignoreWarnings.set(true) // Cette option permet d'ignorer les avertissements
                }
            }
        }

        nativeDistributions {
            targetFormats(TargetFormat.Pkg, TargetFormat.Exe, TargetFormat.Deb)
            packageName = "Android Tools"
            packageVersion = "1.0.0"

            macOS {
                iconFile.set(project.file("src/commonMain/composeResources/drawable/icon.icns"))
            }

            windows {
                iconFile.set(project.file("src/commonMain/composeResources/drawable/icon.ico"))
            }
        }
    }
}
