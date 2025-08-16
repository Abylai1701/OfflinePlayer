import SwiftUI

struct TrendingNowView: View {
    
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = TrendingNowViewModel()
    
    @State private var search: String = ""
    @State private var sheetContentHeight: CGFloat = 430

    var body: some View {
        ScrollView {
            VStack(spacing: 16.fitH) {
                
                // Header
                HStack(spacing: 12.fitW) {
                    Button {
                        viewModel.back()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18.fitW, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 14.fitW, height: 28.fitH)
                            .contentShape(Rectangle())
                    }
                    
                    Text("Trending Now")
                        .font(.manropeExtraBold(size: 24.fitH))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.top, 16.fitH)
                .padding(.horizontal, 16.fitW)
                
                // Search
                SearchBar(text: $search)
                    .padding(.horizontal, 16.fitW)
                
                // List
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.items) { track in
                        TrendingRow(
                            rank: 7,
                            cover: track.cover,
                            title: track.title,
                            artist: track.artist,
                            onMenuTap: {
                                viewModel.openActions(for: track)
                            }
                        )
                        .padding(.horizontal, 16.fitW)
                    }
                }
                .padding(.bottom, 24.fitH)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .task {
            viewModel.attach(router: router)
            
            if viewModel.items.isEmpty {
                viewModel.items = [
                    Track(title: "Lost in Static", artist: "Kai Verne", cover: Image(.image)),
                    Track(title: "Dreamy Skies", artist: "Luma Rae", cover: Image(.image)),
                    Track(title: "Dreamy Skies", artist: "Luma Rae", cover: Image(.image)),
                    Track(title: "Dreamy Skies", artist: "Luma Rae", cover: Image(.image)),
                    Track(title: "Dreamy Skies", artist: "Luma Rae", cover: Image(.image)),
                    Track(title: "Lost in Static", artist: "Kai Verne", cover: Image(.image)),
                    Track(title: "Lost in Static", artist: "Kai Verne", cover: Image(.image)),
                    Track(title: "Lost in Static", artist: "Kai Verne", cover: Image(.image)),
                    Track(title: "No Sleep City", artist: "Drex Malone", cover: Image(.image)),
                    Track(title: "No Sleep City", artist: "Drex Malone", cover: Image(.image)),
                    Track(title: "Lost in Static", artist: "Kai Verne", cover: Image(.image))
                ]
            }
        }
        .sheet(isPresented: $viewModel.isActionSheetPresented) {
            if let t = viewModel.actionTrack {
                TrackActionsSheet(
                    track: t,
                    onLike: { viewModel.like(); viewModel.closeActions() },
                    onAddToPlaylist: { viewModel.addToPlaylist(); viewModel.closeActions() },
                    onPlayNext: { viewModel.playNext(); viewModel.closeActions() },
                    onDownload: { viewModel.download(); viewModel.closeActions() },
                    onShare: { viewModel.share(); viewModel.closeActions() },
                    onGoToAlbum: { viewModel.goToAlbum(); viewModel.closeActions() },
                    onRemove: { viewModel.remove(); viewModel.closeActions() },
                    idealHeight: $sheetContentHeight,   //height that need to us
                )
                .applyCustomDetent(height: sheetHeightClamped)
                .presentationCornerRadius(28.fitW)
                .presentationDragIndicator(.visible)
            }
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
        .blur(radius: viewModel.isActionSheetPresented ? 0 : 0)
        .overlay {
            if viewModel.isActionSheetPresented {
                Color.black.opacity(0.4).ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isActionSheetPresented)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var sheetHeightClamped: CGFloat {
        let screenH = UIScreen.main.bounds.height
        return min(sheetContentHeight, screenH * 0.9)
    }
}



//// Mock примеры данных
//private let sampleTitles  = ["Lost in Static", "Dreamy Skies", "No Sleep City",
//                             "Fireproof Heart", "Mirror Maze", "Midnight Carousel",
//                             "Runaway Signal", "Hello"]
//private let sampleArtists = ["Kai Verne", "Luma Rae", "Drex Malone",
//                             "Novaa", "Arlo Mav", "The Amber Skies",
//                             "KERO & Flashline", "—"]
#Preview {
    TrendingNowView()
        .environmentObject(Router())
}
