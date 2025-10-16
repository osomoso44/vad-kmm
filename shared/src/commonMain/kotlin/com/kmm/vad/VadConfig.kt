package com.kmm.vad

/**
 * Configuration for Voice Activity Detection
 */
data class VadConfig(
    val sampleRate: SampleRate = SampleRate.SAMPLE_RATE_16K,
    val frameSize: FrameSize = FrameSize.FRAME_SIZE_512,
    val mode: VadMode = VadMode.NORMAL,
    val minimumSilenceDurationMs: Int = 300,
    val minimumSpeechDurationMs: Int = 30,
    val silenceDurationMs: Int = 5000,
    val maxRecordingDurationMs: Int = 60000,
    val recordSpeechOnly: Boolean = false,
    val sileroModelVersion: SileroModelVersion = SileroModelVersion.V5,
    val vadStartDetectionProbability: Float = 0.7f,
    val vadEndDetectionProbability: Float = 0.7f,
    val voiceStartVadTrueRatio: Float = 0.8f,
    val voiceEndVadFalseRatio: Float = 0.95f,
    val voiceStartFrameCount: Int = 10,
    val voiceEndFrameCount: Int = 57
)

/**
 * Supported sample rates
 */
enum class SampleRate(val value: Int) {
    SAMPLE_RATE_8K(8000),
    SAMPLE_RATE_16K(16000),
    SAMPLE_RATE_24K(24000),
    SAMPLE_RATE_48K(48000);

    companion object {
        fun fromValue(value: Int): SampleRate? = entries.find { it.value == value }
    }
}

/**
 * Supported frame sizes (in samples)
 */
enum class FrameSize(val value: Int) {
    FRAME_SIZE_256(256),
    FRAME_SIZE_512(512),
    FRAME_SIZE_768(768),
    FRAME_SIZE_1024(1024);

    companion object {
        fun fromValue(value: Int): FrameSize? = entries.find { it.value == value }
    }
}

/**
 * VAD detection modes
 */
enum class VadMode(val value: Int) {
    VERY_AGGRESSIVE(0),
    AGGRESSIVE(1),
    NORMAL(2),
    LOW_BITRATE(3),
    QUALITY(4);

    companion object {
        fun fromValue(value: Int): VadMode? = entries.find { it.value == value }
    }
}

/**
 * Silero model versions
 */
enum class SileroModelVersion(val value: Int) {
    V4(0),
    V5(1);

    companion object {
        fun fromValue(value: Int): SileroModelVersion? = entries.find { it.value == value }
    }
}

