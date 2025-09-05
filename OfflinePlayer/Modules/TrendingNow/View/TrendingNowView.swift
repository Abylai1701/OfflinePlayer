import SwiftUI
import SwiftData

struct TrendingNowView: View {
    
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: TrendingNowViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var sheetContentHeight: CGFloat = 430
    @StateObject private var speech = VoiceSearchRecognizer()
    
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
                    SearchBar(text: $viewModel.search,
                              isRecording: speech.isRecording,
                              onMicTap: {
                                    speech.toggle { [weak viewModel] text in
                                        Task { @MainActor in
                                                viewModel?.search = text
                                                viewModel?.onSearchTextChanged()
                                        }
                                    }
                        }
                    )
                        .padding(.bottom, 16.fitH)
                        .onChange(of: viewModel.search) { _, _ in
                            viewModel.onSearchTextChanged()
                        }
                    LazyVStack(spacing: 14.fitH) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, t in
                            TrackCell(
                                rank: idx + 1,
                                coverURL: t.artworkURL,
                                title: t.title,
                                artist: t.artist,
                                onMenuTap: { viewModel.openActions(for: t) }
                            )
                            .onTapGesture {
                                Task {
                                    await PlaybackService.shared.playQueue(viewModel.items, startAt: idx)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24.fitH)
                }
                .padding(.bottom, 200)
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
                viewModel.bindIfNeeded(context: modelContext)
                try? await speech.ensurePermissions()
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
                    onLike: {
                        viewModel.isActionSheetPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            viewModel.addCurrentTrackToFavorites()
                        }
                    },
                    onPlayNext: {
                        viewModel.playNext(track: t)
                        viewModel.closeActions()
                    },
                    onDownload: {
                        viewModel.download(t);
                        viewModel.closeActions() },
                    onShare: {
                        viewModel.closeActions()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            viewModel.shareCurrentTrack()
                        }
                    },
                    onRemove: { viewModel.remove(); viewModel.closeActions() }
                )
                .presentationDetents([.height(290)])
                .presentationCornerRadius(28.fitW)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            ShareSheet(items: viewModel.shareItems)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
