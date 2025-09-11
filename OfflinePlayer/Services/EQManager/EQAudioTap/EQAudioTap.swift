import AVFoundation
import CoreMedia
import Accelerate

// MARK: - Biquad (peaking + shelf)

final class Biquad {
    enum FilterType { case peaking, lowShelf, highShelf }
    
    private var a1: Float = 0, a2: Float = 0
    private var b0: Float = 1, b1: Float = 0, b2: Float = 0
    private var z1: Float = 0, z2: Float = 0
    
    init(type: FilterType, freq: Double, gainDB: Double, q: Double, sampleRate: Double) {
        let A  = pow(10.0, gainDB / 40.0)
        let w0 = 2.0 * Double.pi * (freq / sampleRate)
        let alpha = sin(w0) / (2.0 * q)
        let cosw0 = cos(w0)
        
        var b0d=1.0, b1d=0.0, b2d=0.0, a0d=1.0, a1d=0.0, a2d=0.0
        
        switch type {
        case .peaking:
            b0d = 1 + alpha * A
            b1d = -2 * cosw0
            b2d = 1 - alpha * A
            a0d = 1 + alpha / A
            a1d = -2 * cosw0
            a2d = 1 - alpha / A
            
        case .lowShelf:
            let sqrtA = sqrt(A)
            let twoSqrtAAlpha = 2 * sqrtA * alpha
            b0d =    A * ((A+1) - (A-1)*cosw0 + twoSqrtAAlpha)
            b1d =  2*A * ((A-1) - (A+1)*cosw0)
            b2d =    A * ((A+1) - (A-1)*cosw0 - twoSqrtAAlpha)
            a0d =        (A+1) + (A-1)*cosw0 + twoSqrtAAlpha
            a1d =   -2 * ((A-1) + (A+1)*cosw0)
            a2d =        (A+1) + (A-1)*cosw0 - twoSqrtAAlpha
            
        case .highShelf:
            let sqrtA = sqrt(A)
            let twoSqrtAAlpha = 2 * sqrtA * alpha
            b0d =    A * ((A+1) + (A-1)*cosw0 + twoSqrtAAlpha)
            b1d = -2*A * ((A-1) + (A+1)*cosw0)
            b2d =    A * ((A+1) + (A-1)*cosw0 - twoSqrtAAlpha)
            a0d =        (A+1) - (A-1)*cosw0 + twoSqrtAAlpha
            a1d =    2 * ((A-1) - (A+1)*cosw0)
            a2d =        (A+1) - (A-1)*cosw0 - twoSqrtAAlpha
        }
        
        // нормализация на a0
        b0 = Float(b0d / a0d)
        b1 = Float(b1d / a0d)
        b2 = Float(b2d / a0d)
        a1 = Float(a1d / a0d)
        a2 = Float(a2d / a0d)
    }
    
    @inline(__always)
    func process(_ x: Float) -> Float {
        // Direct Form I (с двумя задержками)
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }
    
    func reset() { z1 = 0; z2 = 0 }
}

// MARK: - EQ Tap

final class EQAudioTap {
    private(set) var tap: MTAudioProcessingTap!
    
    private var sampleRate: Double = 44100
    private var channels: Int = 2
    
    // biquads[channel][band]
    private var biquads: [[Biquad]] = []
    
    private var cachedBands: [EQBandSetting] = []
    private var cachedIsOn: Bool = true
    
    private let eq: EqualizerManager
    
    init(eq: EqualizerManager = .shared) {
        self.eq = eq

        createTap()

        Task { @MainActor [weak self, weak eq] in
            guard let self, let eq else { return }
            self.cachedBands = eq.bands
            self.cachedIsOn  = eq.isOn
            self.rebuildFilters()

            eq.onDidChange = { [weak self, weak eq] in
                guard let self, let eq else { return }
                Task { @MainActor in
                    self.cachedBands = eq.bands
                    self.cachedIsOn  = eq.isOn
                    self.rebuildFilters()
                }
            }
        }
    }


    
    private func createTap() {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            init: tapInitCallback,
            finalize: tapFinalizeCallback,
            prepare: tapPrepareCallback,
            unprepare: tapUnprepareCallback,
            process: tapProcessCallback
        )
        var tapOut: Unmanaged<MTAudioProcessingTap>?
        MTAudioProcessingTapCreate(
            kCFAllocatorDefault,
            &callbacks,
            kMTAudioProcessingTapCreationFlag_PostEffects,
            &tapOut
        )
        tap = tapOut!.takeRetainedValue()
    }
    
    private func rebuildFilters() {
        guard channels > 0 else { biquads = []; return }
        biquads = Array(repeating: [], count: channels)
        
        for ch in 0..<channels {
            var chain: [Biquad] = []
            for (i, b) in cachedBands.enumerated() {
                let type: Biquad.FilterType =
                (i == 0) ? .lowShelf :
                (i == cachedBands.count - 1) ? .highShelf : .peaking
                chain.append(Biquad(
                    type: type,
                    freq: b.freq,
                    gainDB: b.gainDB,
                    q: b.q,
                    sampleRate: sampleRate
                ))
            }
            biquads[ch] = chain
        }
    }
    
    /// callback-safe: обновить формат и пересобрать фильтры
    fileprivate func updateFormat(_ asbd: AudioStreamBasicDescription) {
        self.sampleRate = asbd.mSampleRate
        self.channels   = Int(asbd.mChannelsPerFrame)
        rebuildFilters()
    }
    
    // Обработка буферов (Float32, interleaved/mono)
    nonisolated func processBuffers(_ abl: UnsafeMutablePointer<AudioBufferList>, frames: CMItemCount) {
        guard cachedIsOn, !biquads.isEmpty else { return }
        let frameCount = Int(frames)
        
        let list = UnsafeMutableAudioBufferListPointer(abl)
        for buf in list {
            guard let mData = buf.mData else { continue }
            let chans = Int(buf.mNumberChannels)
            let totalSamples = frameCount * max(chans, 1)
            let ptr = mData.bindMemory(to: Float.self, capacity: totalSamples)
            
            if chans <= 1 {
                var chain = biquads[0]
                for i in 0..<frameCount {
                    var y = ptr[i]
                    for f in chain { y = f.process(y) }
                    ptr[i] = y
                }
            } else {
                let usedChans = min(chans, biquads.count)
                for ch in 0..<usedChans {
                    var chain = biquads[ch]
                    var i = ch
                    while i < totalSamples {
                        var y = ptr[i]
                        for f in chain { y = f.process(y) }
                        ptr[i] = y
                        i += chans
                    }
                }
            }
        }
    }
}

// MARK: - Typed callbacks (@convention(c))

private let tapInitCallback: MTAudioProcessingTapInitCallback = { tap, clientInfo, tapStorageOut in
    tapStorageOut.pointee = clientInfo
}

private let tapFinalizeCallback: MTAudioProcessingTapFinalizeCallback = { _ in
    // no-op
}

private let tapPrepareCallback: MTAudioProcessingTapPrepareCallback = { tap, _, processingFormat in
    let me = Unmanaged<EQAudioTap>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
    me.updateFormat(processingFormat.pointee)
}

private let tapUnprepareCallback: MTAudioProcessingTapUnprepareCallback = { _ in
    // no-op
}

private let tapProcessCallback: MTAudioProcessingTapProcessCallback = {
    tap, numberFrames, /* input */ flags, bufferListInOut, numberFramesOut, /* output */ flagsOut in

    // забираем исходный звук из цепочки
    var srcFlags: MTAudioProcessingTapFlags = 0
    var tr = CMTimeRange()
    MTAudioProcessingTapGetSourceAudio(
        tap,
        numberFrames,
        bufferListInOut,
        &srcFlags,     // ← flagsOut
        &tr,           // ← timeRangeOut
        numberFramesOut
    )

    // пробрасываем флаги наверх
    flagsOut.pointee = srcFlags

    // применяем EQ на количестве реально полученных сэмплов
    let me = Unmanaged<EQAudioTap>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
    me.processBuffers(bufferListInOut, frames: numberFramesOut.pointee)
}

