package com.kmm.vad

/**
 * iOS implementation of VoiceActivityDetectorFactory
 * Creates iOS-specific VAD instances
 */
actual object VoiceActivityDetectorFactory {
    actual fun create(config: VadConfig, callback: VadCallback): VoiceActivityDetector {
        return IosVoiceActivityDetector(config, callback)
    }
}
