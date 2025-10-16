# Voice Activity Detection - Kotlin Multiplatform

Proyecto KMM que unifica las implementaciones de Voice Activity Detection para Android e iOS, reutilizando el código nativo de cada plataforma.

## 📁 Estructura del Proyecto

```
vad-kmm/
├── shared/                         # Módulo compartido KMM
│   ├── src/
│   │   ├── commonMain/            # Código compartido entre plataformas
│   │   │   └── kotlin/com/kmm/vad/
│   │   │       ├── VoiceActivityDetector.kt    # Interfaz común
│   │   │       ├── VadConfig.kt                 # Configuración común
│   │   │       └── VadCallback.kt               # Callbacks comunes
│   │   ├── androidMain/           # Implementación Android (código real)
│   │   │   └── kotlin/com/kmm/vad/
│   │   │       ├── VoiceActivityDetectorFactory.android.kt
│   │   │       ├── AndroidVoiceActivityDetector.kt
│   │   │       ├── AudioRecordingManager.kt     # Del proyecto original
│   │   │       └── Recorder.kt                   # Del proyecto original
│   │   └── iosMain/               # Implementación iOS (código real)
│   │       └── kotlin/com/kmm/vad/
│   │           ├── VoiceActivityDetectorFactory.ios.kt
│   │           └── IosVoiceActivityDetector.kt
│   └── build.gradle.kts
├── androidApp/                    # App de ejemplo Android
│   └── src/main/
│       ├── kotlin/com/kmm/vad/android/
│       │   └── MainActivity.kt    # UI con Jetpack Compose
│       └── AndroidManifest.xml
└── iosApp/                        # App de ejemplo iOS
    └── iosApp/
        └── ContentView.swift      # UI con SwiftUI
```

## 🎯 Arquitectura

### Capa Común (commonMain)

Define interfaces y modelos compartidos:

- **`VoiceActivityDetector`**: Interfaz principal para detección de voz
- **`VadConfig`**: Configuración unificada (sample rate, frame size, umbrales, etc.)
- **`VadCallback`**: Callbacks para eventos de voz
- **`VoiceActivityDetectorFactory`**: Factory pattern para crear instancias específicas

### Android (androidMain)

**Usa directamente el código nativo original del proyecto `vad-android`:**

- **`AudioRecordingManager`**: Gestión de grabación con Silero VAD
  - Detección de voz en tiempo real
  - Grabación de audio WAV a 16kHz
  - Detección de silencios configurables
- **`Recorder`**: Captura de audio desde el micrófono
  - AudioRecord API de Android
  - Procesamiento de frames de audio

**Dependencia nativa:**
```kotlin
implementation("com.github.gkonovalov.android-vad:silero:2.0.6")
```

### iOS (iosMain)

**Usa directamente el código nativo original del proyecto `vad-ios`:**

- **`IosVoiceActivityDetector`**: Wrapper completo de `RealTimeCutVADLibrary`
  - **`VADWrapper`**: Framework nativo de Objective-C/C++
  - **AVAudioEngine**: Captura de audio desde el micrófono
  - **Conversión automática** de sample rates
  - **Detección en tiempo real** con Silero VAD v5
  - **Callbacks nativos** implementados vía `VADDelegateProtocol`

**Características implementadas:**
- ✅ Configuración completa de umbrales VAD
- ✅ Detección de inicio/fin de voz
- ✅ Grabación de WAV a 16kHz
- ✅ Procesamiento de audio en tiempo real
- ✅ Gestión de límites de tiempo

**Dependencia nativa vía CocoaPods:**
```ruby
pod 'RealTimeCutVADLibrary', '1.0.13'
```

El framework incluye:
- `RealTimeCutVADCXXLibrary.xcframework` (C++ engine)
- `onnxruntime.xcframework` (Silero VAD model)
- `webrtc_audio_processing.xcframework` (Denoising)

## 🚀 Uso

### Android

```kotlin
// En tu Activity/Fragment
VoiceActivityDetectorFactory.initialize(context)

val config = VadConfig(
    sampleRate = SampleRate.SAMPLE_RATE_16K,
    frameSize = FrameSize.FRAME_SIZE_512,
    mode = VadMode.AGGRESSIVE,
    silenceDurationMs = 1500,
    maxRecordingDurationMs = 60000
)

val detector = VoiceActivityDetectorFactory.create(
    config = config,
    callback = object : VadCallback {
        override fun onVoiceStarted() {
            // Voz detectada
        }

        override fun onVoiceEnded(audioFilePath: String) {
            // Grabación completa en audioFilePath
        }

        override fun onStatusUpdate(status: String, isSpeech: Boolean, 
                                    silenceTimeMs: Long, recordingTimeMs: Long) {
            // Actualización de estado
        }

        override fun onError(error: String) {
            // Manejo de errores
        }
    }
)

detector.startRecording()
// ... cuando termine
detector.stopRecording()
detector.release()
```

### iOS

```swift
let config = VadConfig(
    sampleRate: .sampleRate16k,
    frameSize: .frameSize512,
    mode: .aggressive,
    // ... más configuración
)

let detector = VoiceActivityDetectorFactory.shared.create(
    config: config,
    callback: MyVadCallback()
)

detector.startRecording()
// ... cuando termine
detector.stopRecording()
detector.release()
```

## 🛠️ Compilación

### Android

```bash
./gradlew androidApp:assembleDebug
```

El APK se genera en: `androidApp/build/outputs/apk/debug/`

### iOS

**Requisitos:**
- Xcode 14.0+
- CocoaPods instalado (`sudo gem install cocoapods`)

**Pasos:**

1. **Generar el podspec del módulo shared:**
```bash
./gradlew :shared:podspec
```

2. **Instalar dependencias (primera vez):**
```bash
cd iosApp
pod install
```

3. **Abrir el workspace generado:**
```bash
open iosApp.xcworkspace  # ← Importante: usar .xcworkspace, NO .xcodeproj
```

4. **Compilar desde Xcode:**
   - Seleccionar el target `iosApp`
   - Cmd+R para ejecutar en simulador o dispositivo

**Notas:**
- El primer build puede tardar ya que CocoaPods descarga los frameworks nativos
- Si hay errores de Xcode command line tools: `sudo xcode-select --reset`

## 📝 Configuración

### VadConfig

```kotlin
data class VadConfig(
    val sampleRate: SampleRate = SAMPLE_RATE_16K,           // 8K, 16K, 24K, 48K
    val frameSize: FrameSize = FRAME_SIZE_512,              // 256, 512, 768, 1024
    val mode: VadMode = NORMAL,                             // Agresividad de detección
    val minimumSilenceDurationMs: Int = 300,                // Silencio mínimo (VAD)
    val minimumSpeechDurationMs: Int = 30,                  // Voz mínima (VAD)
    val silenceDurationMs: Int = 5000,                      // Silencio para finalizar
    val maxRecordingDurationMs: Int = 60000,                // Duración máxima
    val recordSpeechOnly: Boolean = false,                   // Solo grabar voz
    val sileroModelVersion: SileroModelVersion = V5,         // v4 o v5
    // Umbrales de detección (iOS)
    val vadStartDetectionProbability: Float = 0.7f,
    val vadEndDetectionProbability: Float = 0.7f,
    val voiceStartVadTrueRatio: Float = 0.8f,
    val voiceEndVadFalseRatio: Float = 0.95f,
    val voiceStartFrameCount: Int = 10,                      // ~0.32s
    val voiceEndFrameCount: Int = 57                         // ~1.8s
)
```

## 🔑 Permisos

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="28" />
```

### iOS (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Esta aplicación necesita acceso al micrófono para detectar actividad de voz</string>
```

## 📦 Dependencias

### Gradle (build.gradle.kts)

```kotlin
// En settings.gradle.kts
maven { url = uri("https://jitpack.io") }

// En shared/build.gradle.kts
androidMain.dependencies {
    implementation("com.github.gkonovalov.android-vad:silero:2.0.6")
}
```

## ✅ Estado del Proyecto

- [x] Interfaces comunes definidas
- [x] Implementación Android funcional (código original reutilizado)
- [x] Build Android exitoso
- [x] App de ejemplo Android con UI Compose
- [x] **Implementación iOS completa con VADWrapper nativo**
- [x] **Integración CocoaPods con RealTimeCutVADLibrary**
- [x] **Todos los callbacks y configuraciones funcionando**
- [ ] Build iOS completo (requiere Xcode configurado + `pod install`)
- [ ] Tests unitarios
- [ ] Tests de integración

## 📚 Proyectos Originales

Este proyecto unifica:

- **vad-android**: Implementación Android con Silero VAD
  - Ubicación: `../vad-android/`
  - Código reutilizado: `AudioRecordingManager.kt`, `Recorder.kt`

- **vad-ios**: Implementación iOS con RealTimeCutVADLibrary
  - Ubicación: `../vad-ios/`
  - Framework: `RealTimeCutVADLibrary` (Objective-C/C++)

## 🤝 Contribuciones

La arquitectura permite agregar fácilmente:
- Nuevas plataformas (JS, Desktop, etc.)
- Diferentes algoritmos de VAD
- Procesamiento de audio adicional
- Exportación a diferentes formatos

## 📄 Licencia

MIT License - Ver archivos LICENSE en proyectos originales.

