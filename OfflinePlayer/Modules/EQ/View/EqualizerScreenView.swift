import SwiftUI

struct EqualizerScreenView: View {
    
    @StateObject private var viewModel = EQChartViewModel()
    @EnvironmentObject private var router: Router
    
    @State private var isOn: Bool = false
    @State private var selectedPreset: EQPreset
    private let presets: [EQPreset]
    
    @State private var currentBands: [EQBand]
    
    init() {
        
        let sampleBands: [EQBand] = [
            .init(label: "60 Hz",   gain:  4),
            .init(label: "150 Hz",  gain:  2),
            .init(label: "400 Hz",  gain: -8),
            .init(label: "1.0 kHz", gain: -3),
            .init(label: "2.4 kHz", gain:  0),
            .init(label: "15 kHz",  gain:  3),
        ]
        
        let presets: [EQPreset] = [
            EQPreset(name: "Default", bands: [
                .init(label: "60 Hz",   gain: 0),
                .init(label: "150 Hz",  gain: 0),
                .init(label: "400 Hz",  gain: 0),
                .init(label: "1.0 kHz", gain: 0),
                .init(label: "2.4 kHz", gain: 0),
                .init(label: "15 kHz",  gain: 0),
            ]),
            EQPreset(name: "Custom", bands: sampleBands),
            EQPreset(name: "Rock", bands: [
                .init(label: "60 Hz",   gain: 4),
                .init(label: "150 Hz",  gain: 2),
                .init(label: "400 Hz",  gain: -3),
                .init(label: "1.0 kHz", gain: -1),
                .init(label: "2.4 kHz", gain: 2),
                .init(label: "15 kHz",  gain: 5),
            ]),
            EQPreset(name: "Pop", bands: [
                .init(label: "60 Hz",   gain: 4),
                .init(label: "150 Hz",  gain: 2),
                .init(label: "400 Hz",  gain: -3),
                .init(label: "1.0 kHz", gain: -1),
                .init(label: "2.4 kHz", gain: 2),
                .init(label: "15 kHz",  gain: 5),
            ]),
            EQPreset(name: "Jazz", bands: [
                .init(label: "60 Hz",   gain: 0),
                .init(label: "150 Hz",  gain: 2),
                .init(label: "400 Hz",  gain: 4),
                .init(label: "1.0 kHz", gain: 2),
                .init(label: "2.4 kHz", gain: 0),
                .init(label: "15 kHz",  gain: 0),
            ]),
            EQPreset(name: "Acoustic", bands: [
                .init(label: "60 Hz",   gain: 2),
                .init(label: "150 Hz",  gain: 3),
                .init(label: "400 Hz",  gain: 0),
                .init(label: "1.0 kHz", gain: 0),
                .init(label: "2.4 kHz", gain: 1),
                .init(label: "15 kHz",  gain: 2),
            ]),
            EQPreset(name: "Bass Boost", bands: [
                .init(label: "60 Hz",   gain: 2),
                .init(label: "150 Hz",  gain: 2),
                .init(label: "400 Hz",  gain: 1),
                .init(label: "1.0 kHz", gain: 2),
                .init(label: "2.4 kHz", gain: 1),
                .init(label: "15 kHz",  gain: 0),
            ]),
            EQPreset(name: "Treble Boost", bands: [
                .init(label: "60 Hz",   gain: 8),
                .init(label: "150 Hz",  gain: 6),
                .init(label: "400 Hz",  gain: 3),
                .init(label: "1.0 kHz", gain: 0),
                .init(label: "2.4 kHz", gain: -2),
                .init(label: "15 kHz",  gain: 4),
            ]),
            EQPreset(name: "Vocal", bands: [
                .init(label: "60 Hz",   gain: -2),
                .init(label: "150 Hz",  gain: 0),
                .init(label: "400 Hz",  gain: 2),
                .init(label: "1.0 kHz", gain: 3),
                .init(label: "2.4 kHz", gain: 4),
                .init(label: "15 kHz",  gain: 3),
            ]),
        ]
        
        self.presets = presets
        _selectedPreset = State(initialValue: presets[0])
        _currentBands   = State(initialValue: presets[0].bands)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        isOn = false
                        router.pop()
                    } label: {
                        Image("backIcon")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 14.fitW, height: 28.fitW)
                            .contentShape(Rectangle())
                    }
                    
                    Text("Equalizer")
                        .font(.manropeBold(size: 24.fitW))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .tint(.blue)
                        .onChange(of: isOn) { _, v in //Nureke
                            PlaybackService.shared.setEqualizer(isOn: v,
                                                                bands: currentBands,
                                                                restartIfNeeded: v)
                        }
                }
                .padding(.top)
                .padding(.horizontal)
                .padding(.bottom, 20.fitH)
                
                // Chart
                EQChartView(bands: currentBands)
                    .frame(height: 240.fitH)
                    .padding(.horizontal)
                    .opacity(isOn ? 1 : 0.4)
                    .padding(.bottom, 38.fitH)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(presets) { preset in
                            Button {
                                selectedPreset = preset
                                currentBands = preset.bands
                                PlaybackService.shared.setEqualizer(isOn: isOn, //Nureke
                                                                    bands: preset.bands,
                                                                    restartIfNeeded: false)
                            } label: {
                                HStack {
                                    Text(preset.name)
                                        .font(.system(size: 20, weight: .regular))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if preset.id == selectedPreset.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(height: 45.fitH)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .overlay(
                                Divider()
                                    .background(.gray2C2C2C.opacity(0.8)),
                                alignment: .bottom
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Preview

#Preview {
    EqualizerScreenView()
        .environmentObject(Router())
}

