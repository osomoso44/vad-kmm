package com.kmm.vad

import android.content.Context

actual object VoiceActivityDetectorFactory {
    private var applicationContext: Context? = null

    fun initialize(context: Context) {
        applicationContext = context.applicationContext
    }

    actual fun create(config: VadConfig, callback: VadCallback): VoiceActivityDetector {
        val context = applicationContext
            ?: throw IllegalStateException(
                "VoiceActivityDetectorFactory must be initialized with a Context. " +
                "Call VoiceActivityDetectorFactory.initialize(context) before creating a detector."
            )
        return AndroidVoiceActivityDetector(context, config, callback)
    }
}

