import Foundation
import AVFAudio
import Speech

@MainActor
final class VoiceSearchRecognizer: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var transcript: String = ""
    @Published var lastError: String?
    
    private let recognizer = SFSpeechRecognizer(locale: .current)
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    enum VError: LocalizedError {
        case speechDenied, micDenied
        case noInputRoute
        case invalidInputFormat
        case simulatorDisabled(String)
        
        var errorDescription: String? {
            switch self {
            case .speechDenied:
                return "Speech recognition not authorized."
            case .micDenied:
                return "Microphone access not authorized."
            case .noInputRoute:
                return "No audio input available."
            case .invalidInputFormat:
                return "Invalid mic format (sample rate / channel count)."
            case .simulatorDisabled(let hint):
                return hint
            }
        }
    }
    
    // MARK: Permissions (iOS 17+ safe)
    func ensurePermissions() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            SFSpeechRecognizer.requestAuthorization { status in
                status == .authorized
                ? cont.resume(returning: ())
                : cont.resume(throwing: VError.speechDenied)
            }
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    granted ? cont.resume(returning: ()) : cont.resume(throwing: VError.micDenied)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    granted ? cont.resume(returning: ()) : cont.resume(throwing: VError.micDenied)
                }
            }
        }
    }
    
    // MARK: Start / Stop
    func toggle(onPartial: @escaping (String) -> Void) {
        if isRecording { stop() }
        else {
            Task {
                do {
                    try await ensurePermissions()
                    try await start(onPartial: onPartial)
                } catch {
                    lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
    
    func start(onPartial: @escaping (String) -> Void) async throws {
        //        stop()
        
#if targetEnvironment(simulator)
        throw VError.simulatorDisabled(
            "Voice input is disabled on the Simulator. Use a real device, или в Симуляторе включите I/O ▸ Audio Input ▸ MacBook Microphone и перезапустите."
        )
#endif
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        guard session.isInputAvailable else { throw VError.noInputRoute }
        
        let engine = AVAudioEngine()
        self.engine = engine
        
        let input = engine.inputNode
        var format = input.inputFormat(forBus: 0)
        
        if format.sampleRate == 0 || format.channelCount == 0 {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            format = input.inputFormat(forBus: 0)
        }
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw VError.invalidInputFormat
        }
        
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.taskHint = .dictation
        request = req
        
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        
        engine.prepare()
        try engine.start()
        isRecording = true
        transcript = ""
        lastError = nil
        
        task = recognizer?.recognitionTask(with: req) { [weak self] result, err in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcript = text
                    onPartial(text)
                }
                if result.isFinal { self.finish() }
            }
            if let err {
                Task { @MainActor in
                    self.lastError = err.localizedDescription
                    self.finish()
                }
            }
        }
    }
    
    func stop() { finish() }
    
    private func finish() {
        if let engine, engine.isRunning { engine.stop() }
        engine?.inputNode.removeTap(onBus: 0)
        engine = nil
        
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
    }
}
