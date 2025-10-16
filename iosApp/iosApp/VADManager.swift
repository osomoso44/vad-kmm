import Foundation
import AVFoundation
import shared

// Manager para integrar VADWrapper nativo con KMM
class VADManager: NSObject, VADDelegate {
    
    private var vadWrapper: VADWrapper?
    private var audioEngine: AVAudioEngine?
    private var isRecording = false
    private var recordingStartTime: TimeInterval = 0
    private var maxRecordingDurationMs: Int64 = 60000 // 60 segundos por defecto
    
    // Callbacks para KMM
    var onVoiceStarted: (() -> Void)?
    var onVoiceEnded: ((String) -> Void)?
    var onVoiceDataReceived: (([UInt8]) -> Void)?
    var onError: ((String) -> Void)?
    var onStatusUpdate: ((String, Bool, Int64, Int64) -> Void)?
    
    override init() {
        super.init()
        setupVAD()
    }
    
    private func setupVAD() {
        vadWrapper = VADWrapper()
        vadWrapper?.delegate = self
        
        // Configurar con valores por defecto
        vadWrapper?.setSamplerate(.SAMPLERATE_16)
        vadWrapper?.setThresholdWithVadStartDetectionProbability(
            0.5, // vadStartDetectionProbability
            vadEndDetectionProbability: 0.5, // vadEndDetectionProbability
            voiceStartVadTrueRatio: 0.5, // voiceStartVadTrueRatio
            voiceEndVadFalseRatio: 0.5, // voiceEndVadFalseRatio
            voiceStartFrameCount: 10, // voiceStartFrameCount
            voiceEndFrameCount: 10 // voiceEndFrameCount
        )
        vadWrapper?.setSileroModel(.v4)
    }
    
    func configureVAD(config: VadConfig) {
        // Mapear configuración de KMM a VADWrapper nativo
        let sampleRate: SL = .SAMPLERATE_16  // Siempre 16kHz para compatibilidad
        let modelVersion: SMVER = config.sileroModelVersion.value == 1 ? .v5 : .v4
        
        // Configurar duración máxima de grabación
        maxRecordingDurationMs = Int64(config.maxRecordingDurationMs)
        
        vadWrapper?.setSamplerate(sampleRate)
        vadWrapper?.setThresholdWithVadStartDetectionProbability(
            config.vadStartDetectionProbability,
            vadEndDetectionProbability: config.vadEndDetectionProbability,
            voiceStartVadTrueRatio: config.voiceStartVadTrueRatio,
            voiceEndVadFalseRatio: config.voiceEndVadFalseRatio,
            voiceStartFrameCount: Int32(config.voiceStartFrameCount),
            voiceEndFrameCount: Int32(config.voiceEndFrameCount)
        )
        vadWrapper?.setSileroModel(modelVersion)
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        do {
            // Configurar audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord,
                                       mode: .default,
                                       options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            
            // Siempre crear un nuevo audio engine para asegurar un reinicio limpio
            audioEngine = AVAudioEngine()
            
            guard let audioEngine = audioEngine else {
                onError?("Failed to create audio engine")
                return
            }
            
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            
            // Configurar VAD basado en el sample rate real
            configureVADForSampleRate(inputFormat.sampleRate)
            
            // Instalar tap en el input node
            inputNode.installTap(onBus: 0, bufferSize: 4800, format: inputFormat) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer, inputFormat: inputFormat)
            }
            
            // Preparar y iniciar el audio engine
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            recordingStartTime = Date().timeIntervalSince1970
            
        } catch {
            onError?("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        // No establecer audioEngine = nil para permitir reinicio
        isRecording = false
        vadWrapper?.stopRecording() // Asegurarse de detener el VAD nativo
    }
    
    private func configureVADForSampleRate(_ sampleRate: Double) {
        let sampleRateEnum: SL
        switch sampleRate {
        case 48000:
            sampleRateEnum = .SAMPLERATE_48
        case 24000:
            sampleRateEnum = .SAMPLERATE_24
        case 16000:
            sampleRateEnum = .SAMPLERATE_16
        case 8000:
            sampleRateEnum = .SAMPLERATE_8
        default:
            onError?("Unsupported sample rate: \(sampleRate)")
            return
        }
        
        vadWrapper?.setSamplerate(sampleRateEnum)
        onStatusUpdate?("Configured for \(Int(sampleRate))Hz", false, 0, 0)
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        if frameLength > 0 {
            // Procesar audio con VADWrapper nativo
            vadWrapper?.processAudioData(withBuffer: channelData, count: UInt(frameLength))
            
            // Verificar duración máxima de grabación
            let totalRecordingTime = Int64((Date().timeIntervalSince1970 - recordingStartTime) * 1000)
            if totalRecordingTime >= maxRecordingDurationMs {
                stopRecording()
            }
            
            onStatusUpdate?(
                isRecording ? "Recording" : "Stopped",
                false,
                0,
                totalRecordingTime
            )
        }
    }
    
    // MARK: - VADDelegate
    
    func voiceStarted() {
        onVoiceStarted?()
    }
    
    func voiceEnded(withWavData wavData: Data) {
        // Guardar archivo WAV
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "recording_\(Int(Date().timeIntervalSince1970)).wav"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try wavData.write(to: fileURL)
            onVoiceEnded?(fileURL.path)
        } catch {
            onError?("Failed to save WAV file: \(error.localizedDescription)")
        }
    }
    
    func voiceDidContinue(withPCMFloat pcmFloatData: Data) {
        let bytes = Array(pcmFloatData)
        onVoiceDataReceived?(bytes)
    }
}
