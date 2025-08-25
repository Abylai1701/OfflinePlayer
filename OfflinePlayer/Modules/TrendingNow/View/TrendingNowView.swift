import SwiftUI

struct TrendingNowView: View {
    
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: TrendingNowViewModel
    
    @State private var search: String = ""
    @State private var sheetContentHeight: CGFloat = 430
    
    // ← принимаем данные маршрута
    init(items: [MyTrack]) {
        _viewModel = StateObject(wrappedValue: TrendingNowViewModel(items: items))
    }
    
    private var filtered: [MyTrack] {
        let q = viewModel.search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return viewModel.items }
        return viewModel.items.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.artist.localizedCaseInsensitiveContains(q)
        }
    }
    
    var body: some View {
        let blurOn = viewModel.isActionSheetPresented
        
        ZStack {
            
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            VStack(spacing: 16.fitH) {
                HStack(spacing: 8.fitW) {
                    Button {
                        viewModel.back()
                    } label: {
                        Image("backIcon")
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
                
                ScrollView {
                    SearchBar(text: $search)
                        .padding(.bottom, 16.fitH)
                    LazyVStack(spacing: 14.fitH) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, t in
                            // Используй свой компонент с URL (KFImage),
                            // или тот, что мы делали: TrendingRowRemote
                            TrackCell(
                                rank: idx + 1,
                                coverURL: t.artworkURL,
                                title: t.title,
                                artist: t.artist,
                                onMenuTap: { viewModel.openActions(for: t) }
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
            }
        }
        .animation(nil, value: viewModel.isActionSheetPresented)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.isActionSheetPresented) {
            if let t = viewModel.actionTrack {
                TrackActionsSheet(
                    isLocal: false,
                    track: t,
                    coverURL: t.artworkURL,
                    onLike: { viewModel.like(); viewModel.closeActions() },
                    onAddToPlaylist: { viewModel.addToPlaylist(); viewModel.closeActions() },
                    onPlayNext: { viewModel.playNext(); viewModel.closeActions() },
                    onDownload: { viewModel.download(); viewModel.closeActions() },
                    onShare: { viewModel.share(); viewModel.closeActions() },
                    onRemove: { viewModel.remove(); viewModel.closeActions() }
                )
                .presentationDetents([.height(340)])
                .presentationCornerRadius(28.fitW)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            }
        }
    }
}
