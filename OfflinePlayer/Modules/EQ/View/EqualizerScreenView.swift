import SwiftUI

struct EqualizerScreenView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = EQChartViewModel()
    @EnvironmentObject private var router: Router
    
    @State private var isOn: Bool = EqualizerManager.shared.isOn
    @State private var selectedPreset: EQPreset
    
    @Environment(\.dismiss) private var dismiss

    let presets: [EQPreset] = [
        EQPreset(name: "Default", bands: [
            .init(label: "60 Hz", gain: 0),
            .init(label: "150 Hz", gain: 0),
            .init(label: "400 Hz", gain: 0),
            .init(label: "1.0 kHz", gain: 0),
            .init(label: "2.4 kHz", gain: 0),
            .init(label: "15 kHz", gain: 0),
        ]),
        
        EQPreset(name: "Rock", bands: [
            .init(label: "60 Hz", gain: +3),   // лёгкий бас
            .init(label: "150 Hz", gain: +2),   // тело
            .init(label: "400 Hz", gain: -2),   // убираем гул
            .init(label: "1.0 kHz", gain: -1),   // вокал чуть назад
            .init(label: "2.4 kHz", gain: +2),   // атакующие частоты
            .init(label: "15 kHz", gain: +3),   // воздух
        ]),
        
        EQPreset(name: "Pop", bands: [
            .init(label: "60 Hz", gain: +2),   // бас мягче
            .init(label: "150 Hz", gain: +1),
            .init(label: "400 Hz", gain: -1),
            .init(label: "1.0 kHz", gain:  0),   // вокал по центру
            .init(label: "2.4 kHz", gain: +2),   // чёткость
            .init(label: "15 kHz", gain: +3),
        ]),
        
        EQPreset(name: "Jazz", bands: [
            .init(label: "60 Hz", gain:  0),   // натуральный бас
            .init(label: "150 Hz", gain: +1),   // контрабас чуть теплее
            .init(label: "400 Hz", gain: +2),   // тело саксофона
            .init(label: "1.0 kHz", gain: +1),
            .init(label: "2.4 kHz", gain:  0),
            .init(label: "15 kHz", gain: +1),
        ]),
        
        EQPreset(name: "Acoustic", bands: [
            .init(label: "60 Hz", gain: +1),
            .init(label: "150 Hz", gain: +2),   // низ гитары
            .init(label: "400 Hz", gain:  0),
            .init(label: "1.0 kHz", gain:  0),
            .init(label: "2.4 kHz", gain: +1),   // яркость
            .init(label: "15 kHz", gain: +2),   // воздух
        ]),
        
        EQPreset(name: "Bass Boost", bands: [
            .init(label: "60 Hz", gain: +4),   // максимум +4 dB
            .init(label: "150 Hz", gain: +2),
            .init(label: "400 Hz", gain:  0),
            .init(label: "1.0 kHz", gain:  0),
            .init(label: "2.4 kHz", gain:  0),
            .init(label: "15 kHz", gain:  0),
        ]),
        
        EQPreset(name: "Treble Boost", bands: [
            .init(label: "60 Hz", gain:  0),
            .init(label: "150 Hz", gain:  0),
            .init(label: "400 Hz", gain:  0),
            .init(label: "1.0 kHz", gain: +1),
            .init(label: "2.4 kHz", gain: +3),   // чёткость
            .init(label: "15 kHz", gain: +4),   // воздух, но без лишнего шума
        ]),
        
        EQPreset(name: "Vocal", bands: [
            .init(label: "60 Hz", gain: -2),   // убираем гул
            .init(label: "150 Hz", gain:  0),
            .init(label: "400 Hz", gain: +1),
            .init(label: "1.0 kHz", gain: +3),   // голос вперёд
            .init(label: "2.4 kHz", gain: +3),
            .init(label: "15 kHz", gain: +2),   // яркость
        ]),
    ]

    @State private var currentBands: [EQBand]
    
    // MARK: - Init

    init() {
        _selectedPreset = State(initialValue: presets[0])
        _currentBands   = State(initialValue: presets[0].bands)
    }
    
    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            content
            
        }
        .preferredColorScheme(.dark)
    }
    
    private var content: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
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
                    .onChange(of: isOn) { newVal in
                        EqualizerManager.shared.isOn = newVal
                    }
                    .labelsHidden()
                    .tint(.blue)
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, 20.fitH)
            
            miniContent
        }
    }
    
    private var miniContent: some View {
        VStack {
            EQChartView(bands: currentBands)
                .frame(height: 240.fitH)
                .padding(.horizontal)
                .opacity(isOn ? 1 : 0.4)
                .padding(.bottom, 38.fitH)

            miniContenSecond
        }
    }
    
    private var miniContenSecond: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(presets) { preset in
                    PresetRow(
                        preset: preset,
                        isSelected: preset.id == selectedPreset.id,
                        onSelect: {
                            selectedPreset = preset
                            currentBands   = preset.bands

                            // отправляем в EQ
                            EqualizerManager.shared.setBands(
                                preset.bands.map { band in
                                    EQBandSetting(
                                        freq: band.freq,
                                        gainDB: Double(band.gain),
                                        q: 1.0
                                    )
                                }
                            )
                        }
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
    }

}

// MARK: - Preview

#Preview {
    EqualizerScreenView()
        .environmentObject(Router())
}
