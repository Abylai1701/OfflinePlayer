import SwiftUI

struct TrendingNowView: View {
    
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = TrendingNowViewModel()
    
    @State private var search: String = ""
    @State private var sheetContentHeight: CGFloat = 430
    
    var body: some View {
        let blurOn = viewModel.isActionSheetPresented

        ZStack {
            
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading ,spacing: 16.fitH) {
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
                            .font(.manropeBold(size: 24.fitW))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16.fitH)
                    
                    SearchBar(text: $search)
                    
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
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24.fitH)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .compositingGroup()
            .blur(radius: blurOn ? 20 : 0)
            .animation(.easeInOut(duration: 0.3), value: blurOn)
            .scrollIndicators(.hidden)
            .onTapGesture {
                UIApplication.shared.endEditing(true)
            }
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
        }
        .animation(nil, value: viewModel.isActionSheetPresented)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
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
                    onRemove: { viewModel.remove(); viewModel.closeActions() }
                )
                .presentationDetents([.height(462)])
                .presentationCornerRadius(28.fitW)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            }
        }
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
