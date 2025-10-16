package com.kmm.vad

import android.content.Context

class AndroidVoiceActivityDetector(
    private val context: Context,
    private var config: VadConfig,
    private val callback: VadCallback
) : VoiceActivityDetector {

    private var audioRecordingManager: AudioRecordingManager = createAudioRecordingManager()

    private fun createAudioRecordingManager(): AudioRecordingManager {
        return AudioRecordingManager(
            context = context,
            listener = object : AudioRecordingManager.RecordingResultListener {
                override fun onRecordingComplete(audioFilePath: String) {
                    callback.onVoiceEnded(audioFilePath)
                }

                override fun onRecordingError(errorMessage: String) {
                    callback.onError(errorMessage)
                }

                override fun onStatusUpdate(
                    status: String,
                    isSpeech: Boolean,
                    silenceTime: Long,
                    recordingTime: Long
                ) {
                    callback.onStatusUpdate(status, isSpeech, silenceTime, recordingTime)
                    if (isSpeech) {
                        callback.onVoiceStarted()
                    }
                }
            },
            recordSpeechOnly = config.recordSpeechOnly,
            vadMinimumSilenceDurationMs = config.minimumSilenceDurationMs,
            vadMinimumSpeechDurationMs = config.minimumSpeechDurationMs,
            vadMode = config.mode.value,
            silenceDurationMs = config.silenceDurationMs,
            maxRecordingDurationMs = config.maxRecordingDurationMs
        )
    }

    override fun startRecording() {
        audioRecordingManager.startRecording()
    }

    override fun stopRecording() {
        audioRecordingManager.stopRecording()
    }

    override fun isRecording(): Boolean {
        return audioRecordingManager.isRecording()
    }

    override fun updateConfiguration(config: VadConfig) {
        this.config = config
        audioRecordingManager.updateVadMode(config.mode.value)
        audioRecordingManager.updateVadMinimumSilenceDurationMs(config.minimumSilenceDurationMs)
        audioRecordingManager.updateVadMinimumSpeechDurationMs(config.minimumSpeechDurationMs)
        audioRecordingManager.updateSilenceDurationMs(config.silenceDurationMs)
        audioRecordingManager.updateMaxRecordingDurationMs(config.maxRecordingDurationMs)
        audioRecordingManager.updateRecordSpeechOnly(config.recordSpeechOnly)
    }

    override fun release() {
        audioRecordingManager.onDestroy()
    }
}

