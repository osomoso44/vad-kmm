package com.kmm.vad.android

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.kmm.vad.*

class MainActivity : ComponentActivity() {

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            startVAD()
        }
    }

    private var vadDetector: VoiceActivityDetector? = null
    private var statusState = mutableStateOf("Inicializado")
    private var isSpeechState = mutableStateOf(false)
    private var silenceTimeState = mutableStateOf(0L)
    private var recordingTimeState = mutableStateOf(0L)
    private var isRecordingState = mutableStateOf(false)
    private var audioFilesState = mutableStateOf<List<String>>(emptyList())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        VoiceActivityDetectorFactory.initialize(this)

        setContent {
            MyApplicationTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    VADScreen(
                        status = statusState.value,
                        isSpeech = isSpeechState.value,
                        silenceTime = silenceTimeState.value,
                        recordingTime = recordingTimeState.value,
                        isRecording = isRecordingState.value,
                        audioFiles = audioFilesState.value,
                        onStartRecording = { checkPermissionAndStart() },
                        onStopRecording = { 
                            vadDetector?.stopRecording()
                            isRecordingState.value = false
                        }
                    )
                }
            }
        }
    }

    private fun checkPermissionAndStart() {
        when {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO
            ) == PackageManager.PERMISSION_GRANTED -> {
                startVAD()
            }
            else -> {
                requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
            }
        }
    }

    private fun startVAD() {
        if (vadDetector == null) {
            val config = VadConfig(
                sampleRate = SampleRate.SAMPLE_RATE_16K,
                frameSize = FrameSize.FRAME_SIZE_512,
                mode = VadMode.AGGRESSIVE,
                minimumSilenceDurationMs = 300,
                minimumSpeechDurationMs = 30,
                silenceDurationMs = 1500,
                maxRecordingDurationMs = 60000,
                recordSpeechOnly = false,
                sileroModelVersion = SileroModelVersion.V5,
                vadStartDetectionProbability = 0.7f,
                vadEndDetectionProbability = 0.7f,
                voiceStartVadTrueRatio = 0.8f,
                voiceEndVadFalseRatio = 0.95f,
                voiceStartFrameCount = 10,
                voiceEndFrameCount = 47
            )

            vadDetector = VoiceActivityDetectorFactory.create(
                config = config,
                callback = object : VadCallback {
                    override fun onVoiceStarted() {
                        runOnUiThread {
                            statusState.value = "¡Voz detectada!"
                        }
                    }

                    override fun onVoiceEnded(audioFilePath: String) {
                        runOnUiThread {
                            statusState.value = "Grabación completada"
                            audioFilesState.value = audioFilesState.value + audioFilePath
                        }
                    }

                    override fun onVoiceDataReceived(audioData: ByteArray) {
                    }

                    override fun onStatusUpdate(
                        status: String,
                        isSpeech: Boolean,
                        silenceTimeMs: Long,
                        recordingTimeMs: Long
                    ) {
                        runOnUiThread {
                            statusState.value = status
                            isSpeechState.value = isSpeech
                            silenceTimeState.value = silenceTimeMs
                            recordingTimeState.value = recordingTimeMs
                        }
                    }

                    override fun onError(error: String) {
                        runOnUiThread {
                            statusState.value = "Error: $error"
                        }
                    }
                }
            )
        }

        vadDetector?.startRecording()
        isRecordingState.value = true
    }

    override fun onDestroy() {
        super.onDestroy()
        vadDetector?.release()
    }
}

@Composable
fun VADScreen(
    status: String,
    isSpeech: Boolean,
    silenceTime: Long,
    recordingTime: Long,
    isRecording: Boolean,
    audioFiles: List<String>,
    onStartRecording: () -> Unit,
    onStopRecording: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Voice Activity Detector KMM",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 24.dp)
        )

        Box(
            modifier = Modifier
                .size(100.dp)
                .background(
                    color = when {
                        !isRecording -> Color.Gray
                        isSpeech -> Color.Red
                        else -> Color.Green
                    },
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "🎤",
                style = MaterialTheme.typography.displayLarge
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = "Estado: $status")
                Text(text = "Voz: ${if (isSpeech) "Sí" else "No"}")
                Text(text = "Tiempo de silencio: ${silenceTime}ms")
                Text(text = "Tiempo de grabación: ${recordingTime}ms")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            Button(
                onClick = onStartRecording,
                enabled = !isRecording
            ) {
                Text("Iniciar")
            }

            Button(
                onClick = onStopRecording,
                enabled = isRecording
            ) {
                Text("Detener")
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        if (audioFiles.isNotEmpty()) {
            Text(
                text = "Grabaciones (${audioFiles.size})",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            LazyColumn {
                items(audioFiles.reversed()) { filePath ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                    ) {
                        Text(
                            text = filePath.substringAfterLast("/"),
                            modifier = Modifier.padding(16.dp),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        }
    }
}

