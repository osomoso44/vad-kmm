package com.kmm.vad

/**
 * Common interface for Voice Activity Detection across platforms
 */
interface VoiceActivityDetector {
    /**
     * Start recording and detecting voice activity
     */
    fun startRecording()

    /**
     * Stop recording
     */
    fun stopRecording()

    /**
     * Check if currently recording
     */
    fun isRecording(): Boolean

    /**
     * Update VAD configuration
     */
    fun updateConfiguration(config: VadConfig)

    /**
     * Clean up resources
     */
    fun release()
}

/**
 * Callback interface for VAD events
 */
interface VadCallback {
    /**
     * Called when voice activity starts
     */
    fun onVoiceStarted()

    /**
     * Called when voice activity ends with recorded audio data
     * @param audioFilePath Path to the recorded audio file (WAV format, 16kHz)
     */
    fun onVoiceEnded(audioFilePath: String)

    /**
     * Called during voice activity with intermediate audio data
     * @param audioData Raw audio data (format depends on platform)
     */
    fun onVoiceDataReceived(audioData: ByteArray)

    /**
     * Called when recording status changes
     * @param status Current status description
     * @param isSpeech True if currently detecting speech
     * @param silenceTimeMs Time in milliseconds of current silence
     * @param recordingTimeMs Total recording time in milliseconds
     */
    fun onStatusUpdate(
        status: String,
        isSpeech: Boolean,
        silenceTimeMs: Long,
        recordingTimeMs: Long
    )

    /**
     * Called when an error occurs
     * @param error Error message
     */
    fun onError(error: String)
}

/**
 * Factory to create platform-specific VAD instances
 */
expect object VoiceActivityDetectorFactory {
    fun create(config: VadConfig, callback: VadCallback): VoiceActivityDetector
}

