package com.kmm.vad

// Extensiones para mapear los enums de Kotlin a los enums nativos de iOS
// TODO: Implementar cuando tengamos cinterop funcionando

/*
// Mapeo de SampleRate
fun SampleRate.toNative(): SL {
    return when (this) {
        SampleRate.SAMPLE_RATE_8K -> SAMPLERATE_8
        SampleRate.SAMPLE_RATE_16K -> SAMPLERATE_16
        SampleRate.SAMPLE_RATE_24K -> SAMPLERATE_24
        SampleRate.SAMPLE_RATE_48K -> SAMPLERATE_48
    }
}

// Mapeo de SileroModelVersion
fun SileroModelVersion.toNative(): SMVER {
    return when (this) {
        SileroModelVersion.V4 -> v4
        SileroModelVersion.V5 -> v5
    }
}
*/

// Por ahora, funciones placeholder que se implementarán cuando tengamos cinterop
fun SampleRate.toNativeString(): String {
    return when (this) {
        SampleRate.SAMPLE_RATE_8K -> "8kHz"
        SampleRate.SAMPLE_RATE_16K -> "16kHz"
        SampleRate.SAMPLE_RATE_24K -> "24kHz"
        SampleRate.SAMPLE_RATE_48K -> "48kHz"
    }
}

fun SileroModelVersion.toNativeString(): String {
    return when (this) {
        SileroModelVersion.V4 -> "v4"
        SileroModelVersion.V5 -> "v5"
    }
}
