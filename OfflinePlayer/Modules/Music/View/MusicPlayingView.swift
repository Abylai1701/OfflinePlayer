import SwiftUI

struct MusicPlayerView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = MusicPlayingViewModel()
    
    // входные данные
    let cover: Image
    let title: String
    let artist: String
    var onDismiss: () -> Void = {}
    
    // состояние
    @State private var isPlaying   = true
    @State private var isScrubbing = false
    @State private var duration: Double = 117     // 1:57
    @State private var position: Double = 46      // 0:46
    
    @State private var isLiked = false
    @State private var isShuffleOn = false
    @State private var repeatMode: RepeatMode = .off
    @State private var flash: FlashEvent? = nil
    
    // метрики под макет
    private var artCorner: CGFloat { 26.fitW }
    
    var body: some View {
        ZStack {
            backgroundLayer
                .zIndex(0)
            contentLayer
                .zIndex(1)
            
        }
        .task {
            viewModel.attach(router: router)
        }
        .overlay(alignment: .top) {
            topBar
        }
        .safeAreaInset(edge: .bottom) { bottomControls }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var topBar: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20.fitW, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .foregroundStyle(.white)
                }
                Spacer()
                Button { /* more */ } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20.fitW, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 56.fitH + topInset)
            .padding(.horizontal)
            .background(
                LinearGradient(colors: [.black.opacity(0.35), .clear],
                               startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)
            )
        }
        .ignoresSafeArea()
        .frame(height: 0)
    }
    
    // MARK: Background
    private var backgroundLayer: some View {
        GeometryReader { geo in
            let size = geo.size
            let r = max(size.width, size.height) * 0.65
            
            cover
                .resizable()
                .scaledToFill()
                .clipped()
                .blur(radius: 18, opaque: true)
                .overlay(
                    ZStack {
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black.opacity(0.58), location: 0.00),
                                .init(color: .black.opacity(0.38), location: 0.45),
                                .init(color: .clear,               location: 1.00)
                            ]),
                            center: UnitPoint(x: 0.5, y: 0.42),
                            startRadius: 0,
                            endRadius: r
                        )
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black.opacity(0.15), location: 0.00),
                                .init(color: .black.opacity(0.30), location: 0.25),
                                .init(color: .black.opacity(0.50), location: 0.40),
                                .init(color: .black.opacity(1.00), location: 0.60),
                                .init(color: .black.opacity(1.00), location: 1.00)
                            ]),
                            startPoint: .top, endPoint: .bottom
                        )
                    }
                )
                .ignoresSafeArea()
        }
    }
    
    
    // MARK: Content
    private var contentLayer: some View {
        
        VStack(spacing: 0) {
            // Обложка
            ZStack {
                let shape = RoundedRectangle(cornerRadius: artCorner, style: .continuous)
                
                cover
                    .resizable()
                    .scaledToFill()
                    .frame(width: 295.fitW, height: 295.fitH)
                    .clipShape(RoundedRectangle(cornerRadius: artCorner, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
                    .overlay {
                                if flash != nil {
                                    shape
                                        .fill(Color.black.opacity(0.22))
                                        .allowsHitTesting(false)
                                        .transition(.opacity)
                                }
                            }


                if let flash {
                    FlashOverlay(event: flash)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, 62.fitH)
            .padding(.bottom, 40.fitH)

            VStack {
                // Титул
                HStack(spacing: 0) {
                    cover
                        .resizable()
                        .scaledToFill()
                        .frame(width: 55.fitW, height: 55.fitW)
                        .clipShape(Circle())
                        .padding(.trailing, 10.fitW)
                    
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.manropeBold(size: 24.fitW))
                            .foregroundStyle(.white)
                        Text(artist)
                            .font(.manropeSemiBold(size: 14.fitW))
                            .foregroundStyle(.gray707070)
                    }
                    .padding(.trailing, 54.fitW)
                    
                    Button {
                        //
                    } label: {
                        Image("settingMusicIcon")
                            .font(.system(size: 24.fitW, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.trailing, 12.fitW)
                    
                    Button {
                        isLiked.toggle()
                        flashHint(isLiked ? .likeOn : .likeOff)
                    } label: {
                        Image(isLiked ? "favoriteFillSmallMusicIcon" : "favoriteSmallMusicIcon")
                            .font(.system(size: 24.fitW))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
                .padding(.bottom, 40.fitH)
                
                // Прогресс
                VStack() {
                    ThinSeekBar(
                        value: $position,
                        range: 0...duration,
                        trackHeight: 3.fitH,
                        thumbRadius: 6.fitW,
                        activeColor: .white,
                        inactiveColor: .gray707070,
                        onEditingChanged: { isDragging in
                            
                        }
                    )
                    
                    HStack {
                        Text(timeString(position))
                            .font(.manropeRegular(size: 14.fitW))
                            .foregroundStyle(.gray707070)
                        
                        Spacer()
                        
                        Text(timeString(duration))
                            .font(.manropeRegular(size: 14.fitW))
                            .foregroundStyle(.gray707070)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, -20.fitH)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private struct FlashOverlay: View {
        let event: FlashEvent
        
        var body: some View {
            VStack(spacing: 10) {
                Image(symbol)
                    .font(.system(size: 92.fitW, weight: .regular))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
            }
            .padding(20)
            .background(.black.opacity(0.001))
        }
        
        private var symbol: String {
            switch event {
            case .likeOn:     return "favoriteMusicIcon"
            case .likeOff:    return "notFavoriteMusicIcon"
            case .repeatOne:  return "repeatMusicIcon"
            case .repeatOff:  return ""
            case .shuffleOn:  return "shuffleMusicIcon"
            case .shaffleOff: return ""
            }
        }
    }
    
    
    
    private func flashHint(_ e: FlashEvent) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { flash = e }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.25)) { flash = nil }
        }
    }
    
    // MARK: Bottom controls
    private var bottomControls: some View {
        VStack(spacing: 18.fitH) {
            HStack(spacing: .zero) {
                Button {
                    isScrubbing.toggle()
                    if isScrubbing {
                        flashHint(.repeatOne)
                    }
                }
                label: { Image(isScrubbing ? "repeatSmallFillIcon" : "repeatSmallMusicIcon") }
                    .frame(width: 24.fitW, height: 24.fitW)
                    .padding(.trailing, 55.fitW)
                
                Button { }
                label: { Image("backMusicIcon") }
                    .frame(width: 32.fitW, height: 32.fitW)
                    .padding(.trailing, 28.fitW)
                
                Button { isPlaying.toggle() }  label: {
                    ZStack {
                        Circle().fill(.white.opacity(0.16))
                            .frame(width: 66.fitW, height: 66.fitW)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26.fitW, weight: .bold))
                    }
                }
                .frame(width: 66.fitW, height: 66.fitW)
                .padding(.trailing, 28.fitW)
                
                Button {
                }
                label: {
                    Image("NextIcon")
                }
                .frame(width: 32.fitW, height: 32.fitW)
                .padding(.trailing, 55.fitW)
                
                Button {
                    isShuffleOn.toggle()
                    if isShuffleOn {
                        flashHint(.shuffleOn)
                    }
                }
                label: { Image(isShuffleOn ? "shuffleFillSmallIcon" : "shuffleSmallMusicIcon") }
                    .frame(width: 24.fitW, height: 24.fitW)
            }
            .foregroundStyle(.white)
            
            Color.clear.frame(height: 6.fitH)
        }
        .padding(.horizontal)
        .padding(.bottom, 45.fitH)
        .background(
            LinearGradient(colors:
                            [.black.opacity(0.12),
                                .black.opacity(0.06),
                                .clear],
                           startPoint: .bottom, endPoint: .top)
        )
    }
    
   
    
    private func timeString(_ v: Double) -> String {
        let t = Int(v.rounded())
        return String(format: "%d:%02d", t/60, t%60)
    }
}

#Preview {
    MusicPlayerView(
        cover: Image(.cover),
        title: "Pretty Woman",
        artist: "Inga Klaus"
    )
    .environmentObject(Router())
}
