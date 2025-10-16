import SwiftUI
import shared
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = VADViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Activity Detector KMM")
                .font(.title)
                .padding(.top, 40)

            ZStack {
                Circle()
                    .fill(viewModel.microphoneColor)
                    .frame(width: 100, height: 100)

                Text("🎤")
                    .font(.system(size: 50))
            }

            VStack(alignment: .leading, spacing: 10) {
                InfoRow(title: "Estado", value: viewModel.status)
                InfoRow(title: "Voz", value: viewModel.isSpeech ? "Sí" : "No")
                InfoRow(title: "Tiempo de silencio", value: "\(viewModel.silenceTime)ms")
                InfoRow(title: "Tiempo de grabación", value: "\(viewModel.recordingTime)ms")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    viewModel.startRecording()
                }) {
                    Text("Iniciar")
                        .frame(width: 120)
                        .padding()
                        .background(viewModel.isRecording ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isRecording)

                Button(action: {
                    viewModel.stopRecording()
                }) {
                    Text("Detener")
                        .frame(width: 120)
                        .padding()
                        .background(viewModel.isRecording ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isRecording)
            }

            if !viewModel.audioFiles.isEmpty {
                VStack(alignment: .leading) {
                    Text("Grabaciones (\(viewModel.audioFiles.count))")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.audioFiles.reversed(), id: \.self) { filePath in
                                HStack {
                                    Text(URL(fileURLWithPath: filePath).lastPathComponent)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.requestMicrophonePermission()
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text("\(title):")
                .fontWeight(.semibold)
            Text(value)
            Spacer()
        }
    }
}

class VADViewModel: ObservableObject {
    @Published var status: String = "Inicializado"
    @Published var isSpeech: Bool = false
    @Published var silenceTime: Int64 = 0
    @Published var recordingTime: Int64 = 0
    @Published var isRecording: Bool = false
    @Published var audioFiles: [String] = []

    private var vadManager: VADManager?

    var microphoneColor: Color {
        if !isRecording {
            return .gray
        } else if isSpeech {
            return .red
        } else {
            return .green
        }
    }

    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Permiso de micrófono concedido")
                DispatchQueue.main.async {
                    self.setupVADManager()
                }
            } else {
                DispatchQueue.main.async {
                    self.status = "Permiso de micrófono denegado"
                }
            }
        }
    }
    
    private func setupVADManager() {
        vadManager = VADManager()
        
        // Configurar callbacks
        vadManager?.onVoiceStarted = { [weak self] in
            DispatchQueue.main.async {
                self?.status = "¡Voz detectada!"
                self?.isSpeech = true
            }
        }
        
        vadManager?.onVoiceEnded = { [weak self] filePath in
            DispatchQueue.main.async {
                self?.status = "Grabación completada"
                self?.isSpeech = false
                self?.addAudioFile(filePath)
            }
        }
        
        vadManager?.onVoiceDataReceived = { [weak self] audioData in
            // Procesar datos de audio si es necesario
        }
        
        vadManager?.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.status = "Error: \(error)"
            }
        }
        
        vadManager?.onStatusUpdate = { [weak self] status, isSpeech, silenceTime, recordingTime in
            DispatchQueue.main.async {
                self?.status = status
                self?.isSpeech = isSpeech
                self?.silenceTime = silenceTime
                self?.recordingTime = recordingTime
            }
        }
        
        // Configurar VAD con parámetros del proyecto original
        let config = VadConfig(
            sampleRate: .sampleRate16k,
            frameSize: .frameSize512,
            mode: .aggressive,
            minimumSilenceDurationMs: 300,
            minimumSpeechDurationMs: 30,
            silenceDurationMs: 1500,
            maxRecordingDurationMs: 60000,
            recordSpeechOnly: false,
            sileroModelVersion: .v5,
            vadStartDetectionProbability: 0.7,
            vadEndDetectionProbability: 0.7,
            voiceStartVadTrueRatio: 0.8,
            voiceEndVadFalseRatio: 0.95,
            voiceStartFrameCount: 10,
            voiceEndFrameCount: 47
        )
        
        vadManager?.configureVAD(config: config)
    }

    func startRecording() {
        vadManager?.startRecording()
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    func stopRecording() {
        vadManager?.stopRecording()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    func addAudioFile(_ path: String) {
        DispatchQueue.main.async {
            self.audioFiles.append(path)
        }
    }
}

// VADCallbackImpl removido - ahora usamos VADManager nativo directamente

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}