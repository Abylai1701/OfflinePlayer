//import SwiftUI
//
//// MARK: - Player
//
//struct MusicPlayerView2: View {
//    // входные
//    let cover: Image
//    let title: String
//    let artist: String
//    var onDismiss: () -> Void = {}
//
//    // состояние
//    @State private var isPlaying = true
//    @State private var duration: Double = 117
//    @State private var position: Double = 46
//
//    @State private var isLiked = false
//    @State private var isShuffleOn = false
//    @State private var repeatMode: RepeatMode = .off
//    @State private var flash: FlashEvent? = nil  // для анимационных всплывашек
//
//    // метрики
//    private var hPad: CGFloat { 16.fitW }
//    private var artCorner: CGFloat { 24.fitW }
//    private var artSize: CGFloat { UIScreen.main.bounds.width - hPad*2 }
//
//    var body: some View {
//        ZStack {
//            backgroundLayer.zIndex(0)
//            contentLayer.zIndex(1)
//        }
//        .overlay(alignment: .top) { topBar }           // верхний бар всегда сверху
//        .overlay(alignment: .bottom) { bottomControls } // нижние кнопки поверх
//        .preferredColorScheme(.dark)
//        .toolbar(.hidden, for: .navigationBar)
//    }
//
//    // MARK: Background (cover + blur + затемнение с усилением по центру)
//    private var backgroundLayer: some View {
//        GeometryReader { geo in
//            let size = geo.size
//            let r = max(size.width, size.height) * 0.65
//
//            cover
//                .resizable()
//                .scaledToFill()
//                .frame(width: size.width, height: size.height)
//                .clipped()
//                .blur(radius: 18, opaque: true)
//                .overlay(
//                    ZStack {
//                        RadialGradient(
//                            gradient: Gradient(stops: [
//                                .init(color: .black.opacity(0.58), location: 0.00),
//                                .init(color: .black.opacity(0.38), location: 0.45),
//                                .init(color: .clear,               location: 1.00)
//                            ]),
//                            center: UnitPoint(x: 0.5, y: 0.42),
//                            startRadius: 0,
//                            endRadius: r
//                        )
//                        LinearGradient(
//                            colors: [.clear, .black.opacity(0.35), .black.opacity(0.6)],
//                            startPoint: .center, endPoint: .bottom
//                        )
//                    }
//                )
//                .ignoresSafeArea()
//        }
//    }
//
//    // MARK: Top bar
//    private var topBar: some View {
//        GeometryReader { geo in
//            let topInset = geo.safeAreaInsets.top
//            HStack {
//                Button(action: onDismiss) {
//                    Image(systemName: "chevron.down")
//                        .font(.system(size: 20.fitW, weight: .semibold))
//                        .frame(width: 44, height: 44)
//                        .contentShape(Rectangle())
//                        .foregroundStyle(.white)
//                }
//                Spacer()
//                Button { /* more */ } label: {
//                    Image(systemName: "ellipsis")
//                        .font(.system(size: 20.fitW, weight: .semibold))
//                        .frame(width: 44, height: 44)
//                        .contentShape(Rectangle())
//                        .foregroundStyle(.white)
//                }
//            }
//            .padding(.top, topInset + 6)
//            .padding(.horizontal, hPad)
//            .background(
//                LinearGradient(colors: [.black.opacity(0.35), .clear],
//                               startPoint: .top, endPoint: .bottom)
//                    .allowsHitTesting(false)
//            )
//        }
//        .ignoresSafeArea()
//        .frame(height: 0) // сам GeometryReader кладём без доп. высоты
//    }
//
//    // MARK: Content
//    private var contentLayer: some View {
//        VStack(spacing: 0) {
//            // Обложка
//            ZStack {
//                cover
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: artSize, height: artSize)
//                    .clipShape(RoundedRectangle(cornerRadius: artCorner, style: .continuous))
//                    .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
//
//                // всплывающая анимация (лайк / репит / шаффл)
//                if let flash {
//                    FlashOverlay(event: flash)
//                        .transition(.scale.combined(with: .opacity))
//                }
//            }
//            .padding(.top, 14.fitH)
//            .padding(.bottom, 26.fitH)
//
//            // Блок под обложкой
//            VStack(spacing: 0) {
//
//                // Титул
//                HStack(spacing: 12.fitW) {
//                    cover
//                        .resizable().scaledToFill()
//                        .frame(width: 40.fitW, height: 40.fitW)
//                        .clipShape(Circle())
//
//                    VStack(alignment: .leading, spacing: 6.fitH) {
//                        Text(title)
//                            .font(.manropeSemiBold(size: 22.fitW))
//                            .foregroundStyle(.white)
//                        Text(artist)
//                            .font(.manropeRegular(size: 14.fitW))
//                            .foregroundStyle(.white.opacity(0.72))
//                    }
//
//                    Spacer()
//
//                    Button { /* queue */ } label: {
//                        Image(systemName: "list.bullet")
//                            .font(.system(size: 18.fitW, weight: .semibold))
//                    }
//                    .buttonStyle(.plain)
//                    .foregroundStyle(.white)
//
//                    Button {
//                        isLiked.toggle()
//                        flashHint(isLiked ? .likeOn : .likeOff)
//                    } label: {
//                        Image(systemName: isLiked ? "heart.fill" : "heart")
//                            .font(.system(size: 20.fitW, weight: .semibold))
//                    }
//                    .buttonStyle(.plain)
//                    .foregroundStyle(.white)
//                }
//
//                // Прогресс + таймеры
//                VStack(spacing: 8.fitH) {
//                    ThinSeekBar(
//                        value: $position,
//                        range: 0...duration,
//                        trackHeight: 3.fitH,
//                        thumbRadius: 6.fitW,
//                        activeColor: .white,
//                        inactiveColor: .white.opacity(0.35),
//                        onEditingChanged: { _ in }
//                    )
//                    .frame(height: 44) // удобная зона тапа
//
//                    HStack {
//                        Text(timeString(position))
//                            .font(.manropeRegular(size: 12.fitW))
//                            .foregroundStyle(.white.opacity(0.75))
//                        Spacer()
//                        Text(timeString(duration))
//                            .font(.manropeRegular(size: 12.fitW))
//                            .foregroundStyle(.white.opacity(0.6))
//                    }
//                }
//                .padding(.top, 16.fitH)
//            }
//            .padding(.horizontal, hPad)
//
//            Spacer(minLength: 120.fitH) // место под нижние кнопки
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//    }
//
//    // MARK: Bottom controls
//    private var bottomControls: some View {
//        GeometryReader { geo in
//            let bottomInset = geo.safeAreaInsets.bottom
//            VStack(spacing: 18.fitH) {
//                HStack(spacing: 28.fitW) {
//                    // Repeat
//                    Button {
//                        cycleRepeat()
//                    } label: {
//                        Image(systemName: "repeat.1")
//                            .symbolRenderingMode(.monochrome)
//                            .foregroundStyle(repeatMode == .off ? .white.opacity(0.6) : .white)
//                            .font(.system(size: 18.fitW, weight: .semibold))
//                    }
//                    .buttonStyle(.plain)
//
//                    // Backward
//                    Button {
//                        position = max(0, position - 5)
//                    } label: {
//                        Image(systemName: "backward.fill")
//                            .font(.system(size: 24.fitW, weight: .semibold))
//                    }
//                    .buttonStyle(.plain)
//
//                    // Play / Pause
//                    Button { isPlaying.toggle() } label: {
//                        ZStack {
//                            Circle().fill(.white.opacity(0.16))
//                                .frame(width: 68.fitW, height: 68.fitW)
//                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
//                                .font(.system(size: 26.fitW, weight: .bold))
//                        }
//                    }
//                    .buttonStyle(.plain)
//
//                    // Forward
//                    Button {
//                        position = min(duration, position + 5)
//                    } label: {
//                        Image(systemName: "forward.fill")
//                            .font(.system(size: 24.fitW, weight: .semibold))
//                    }
//                    .buttonStyle(.plain)
//
//                    // Shuffle
//                    Button {
//                        isShuffleOn.toggle()
//                        flashHint(isShuffleOn ? .shuffleOn : .shuffleOn)
//                    } label: {
//                        Image(systemName: "shuffle")
//                            .symbolRenderingMode(.monochrome)
//                            .foregroundStyle(isShuffleOn ? .white : .white.opacity(0.6))
//                            .font(.system(size: 18.fitW, weight: .semibold))
//                    }
//                    .buttonStyle(.plain)
//                }
//                .foregroundStyle(.white)
//
//                Color.clear.frame(height: max(6.fitH, bottomInset * 0.5))
//            }
//            .padding(.horizontal, hPad)
//            .padding(.bottom, bottomInset + 8)
//            .background(
//                LinearGradient(colors: [.black.opacity(0.12), .black.opacity(0.06), .clear],
//                               startPoint: .bottom, endPoint: .top)
//            )
//        }
//        .ignoresSafeArea()
//        .frame(height: 0) // GeometryReader как overlay
//    }
//
//    // MARK: Flash helpers
//    private func flashHint(_ e: FlashEvent) {
//        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { flash = e }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
//            withAnimation(.easeOut(duration: 0.25)) { flash = nil }
//        }
//    }
//
//    private func cycleRepeat() {
//        switch repeatMode {
//        case .off:
//            repeatMode = .one
//            flashHint(.repeatOne)
//        case .one:
//            repeatMode = .off
//            flashHint(.repeatOff)
//        }
//    }
//
//    // MARK: Utils
//    private func timeString(_ v: Double) -> String {
//        let t = Int(v.rounded())
//        return String(format: "%d:%02d", t/60, t%60)
//    }
//}
//
//// MARK: - Flash overlay (иконка/текст в центре обложки)
//
//private struct FlashOverlay: View {
//    let event: FlashEvent
//
//    var body: some View {
//        VStack(spacing: 10) {
//            Image(systemName: symbol)
//                .font(.system(size: 92.fitW, weight: .regular))
//                .foregroundStyle(.white)
//                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
//
//            if let text = label {
//                Text(text)
//                    .font(.manropeSemiBold(size: 18.fitW))
//                    .foregroundStyle(.white)
//                    .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
//            }
//        }
//        .padding(20)
//        .background(.black.opacity(0.001)) // чтобы не перехватывать тапы
//        .scaleEffect(1.0)
//        .opacity(1.0)
//    }
//
//    private var symbol: String {
//        switch event {
//        case .likeOn:     return "heart.fill"
//        case .likeOff:    return "heart"
//        case .repeatOne:  return "repeat.1"
//        case .repeatOff:  return "repeat"
//        case .shuffleOn:  return "shuffle"
//        }
//    }
//
//    private var label: String? {
//        switch event {
//        case .repeatOne:  return "Repeat One"
//        case .shuffleOn:  return "Shuffle"
//        default:          return nil
//        }
//    }
//}
//
//
//
//// MARK: - Preview + usage
//
//#Preview {
//    
//        MusicPlayerView2(
//            cover: Image(.cover),
//            title: "Pretty Woman",
//            artist: "Inga Klaus"
//        )
//    }
