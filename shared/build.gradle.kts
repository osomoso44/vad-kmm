import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework

plugins {
    id("org.jetbrains.kotlin.multiplatform")
    id("com.android.library")
}

kotlin {
    androidTarget {
        compilations.all {
            compileTaskProvider.configure {
                compilerOptions {
                    jvmTarget.set(JvmTarget.JVM_1_8)
                }
            }
        }
    }

    val xcf = XCFramework()
    listOf(
        iosX64(),
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "shared"
            isStatic = true
            xcf.add(this)
            
            // Link native frameworks
            linkerOpts("-F${projectDir}/src/iosMain/frameworks")
            linkerOpts("-framework", "RealTimeCutVADCXXLibrary")
            linkerOpts("-framework", "onnxruntime")
            linkerOpts("-framework", "webrtc_audio_processing")
        }
        
        // Cinterop removido - integración directa en proyecto iOS
    }

    sourceSets {
        commonMain.dependencies {
            //put your multiplatform dependencies here
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }
        androidMain.dependencies {
            implementation("com.github.gkonovalov.android-vad:silero:2.0.6")
        }
    }
}

android {
    namespace = "com.kmm.vad"
    compileSdk = 35
    defaultConfig {
        minSdk = 24
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}
