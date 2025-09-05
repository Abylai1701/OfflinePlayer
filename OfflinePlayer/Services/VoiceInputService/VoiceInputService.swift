//
//  VoiceInputService.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 03.09.2025.
//
import Foundation
import AVFoundation
import Speech

@MainActor
final class VoiceInputService: NSObject, ObservableObject {
    
    enum State: Equatable {
        case idle, preparing, recording, finishing
        case denied
        case failed(String)
    }
    
    @Published private(set) var state: State = .idle
    @Published private(set) var transcript: String = ""
    @Published private(set) var isRecording: Bool = false
    
    var locale: Locale { didSet { recognizer = SFSpeechRecognizer(locale: locale) } }
    var requiresOnDeviceRecognition = false
    
    private var recognizer: SFSpeechRecognizer?
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    override init() {
        self.locale = .current
        self.recognizer = SFSpeechRecognizer(locale: .current)
        super.init()
    }
    
    // MARK: - Permissions
    
    func requestPermissions() async -> Bool {
        let speechOK: Bool = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechOK else { state = .denied; return false }
        
        let micOK: Bool = await withCheckedContinuation { cont in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { ok in cont.resume(returning: ok) }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { ok in cont.resume(returning: ok) }
            }
        }
        guard micOK else { state = .denied; return false }
        return true
    }
    
    // MARK: - Start / Stop
    func start(onPartial: ((String) -> Void)? = nil,
               onFinal:   ((String) -> Void)? = nil,
               duckOthers: Bool = true) async {
        guard await requestPermissions() else { return }
        
        stopInternal(resetToIdle: false)
        transcript = ""
        state = .preparing
        
        let session = AVAudioSession.sharedInstance()
        do {
            let opts: AVAudioSession.CategoryOptions = duckOthers
            ? [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            : [.mixWithOthers, .defaultToSpeaker]
            try session.setCategory(.record, mode: .measurement, options: opts)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .failed("Audio session: \(error.localizedDescription)")
            return
        }
        
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if #available(iOS 13.0, *) { req.requiresOnDeviceRecognition = requiresOnDeviceRecognition }
        request = req
        
        guard let recognizer, recognizer.isAvailable else {
            state = .failed("Recognizer not available")
            return
        }
        
        let input = engine.inputNode
        let bus = 0
        let format = input.outputFormat(forBus: bus) // используем HW-формат → не будет -10868
        input.removeTap(onBus: bus)
        input.installTap(onBus: bus, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        
        engine.prepare()
        do { try engine.start() }
        catch {
            input.removeTap(onBus: bus)
            state = .failed("Engine: \(error.localizedDescription)")
            return
        }
        
        isRecording = true
        state = .recording
        
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            
            if let result {
                let text = result.bestTranscription.formattedString
                self.transcript = text
                onPartial?(text)
                if result.isFinal { onFinal?(text) }
            }
            
            if let error {
                self.state = .failed(error.localizedDescription)
                self.stopInternal(resetToIdle: true)
            }
        }
    }
    
    func stop() {
        stopInternal(resetToIdle: true)
    }
    
    private func stopInternal(resetToIdle: Bool) {
        state = .finishing
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isRecording = false
        if resetToIdle { state = .idle }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
