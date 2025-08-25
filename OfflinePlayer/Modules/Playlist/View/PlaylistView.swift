import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject private var router: Router
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PlaylistViewModel()
    
    @State private var search = ""
    @State private var showNewPlaylistAlert = false
    @State private var newPlaylistName = ""
    @State private var showPlayer = false

    
    var body: some View {
        content
            .overlay {
                if showNewPlaylistAlert {
                    NewPlaylistAlertView(
                        isPresented: $showNewPlaylistAlert,
                        text: $newPlaylistName,
                        onSave: { name in
                            viewModel.createPlaylist(named: name)
                        },
                        onCancel: {}
                    )
                }
            }
            .task {
                viewModel.attach(router: router)
                viewModel.bindIfNeeded(context: modelContext)
                viewModel.refresh()
            }
            .onTapGesture {
                UIApplication.shared.endEditing(true)
            }
            .animation(.easeInOut(duration: 0.3), value: showNewPlaylistAlert)
    }
    
    private var content: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: .zero) {

                navBar
                    .padding(.top)
                    .padding(.horizontal)
                    .padding(.bottom)
                
            ScrollView {
                    PlaylistSearchView(searchText: search)
                        .padding(.bottom)

                    NewPlaylistRow(
                        onTap: {
                            newPlaylistName = ""
                            showNewPlaylistAlert = true
                        }
                    )
                    .padding(.horizontal)

                    VStack(spacing: 14) {
                        ForEach(viewModel.playlists) { p in
                            PlaylistCell(
                                cover: coverImage(for: p),
                                title: p.title,
                                subtitle: "\(p.items.count) tracks",
                                onTap: { viewModel.pushToDetail(p) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 120.fitH)
                }
            }
            .scrollIndicators(.hidden)
            .background {
                LinearGradient(colors: [.gray222222, .black111111],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            
            MiniPlayerBar(
                cover: Image(.image),
                title: "Midnight Mirage",
                subtitle: "Léa Vellor",
                onExpand: {
                    showPlayer = true
                },
                onPlay: {},
                onPause: {}
            ).fullScreenCover(isPresented: $showPlayer) {
                MusicPlayerView(
                    cover: Image(.cover),
                    title: "Pretty Woman",
                    artist: "Inga Klaus",
                    onDismiss: { showPlayer = false }
                )
            }
        }
    }
    
    private func coverImage(for p: LocalPlaylist) -> Image {
        if let data = p.artworkData, let ui = UIImage(data: data) {
            return Image(uiImage: ui)
        } else {
            return Image(.emptyPhoto)
        }
    }
    
    private var navBar: some View {
        HStack(spacing: 8.fitW) {
            Button {
                
            } label: {
                Image("backIcon")
                    .foregroundStyle(.white)
                    .frame(width: 14.fitW, height: 28.fitH)
                    .contentShape(Rectangle())
            }
            
            Text("Playlists")
                .font(.manropeBold(size: 24.fitW))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
}

struct MiniPlayerBar: View {
    let cover: Image
    let title: String
    let subtitle: String
    var onExpand: () -> Void = {}
    var onPlay: () -> Void = {}
    var onPause: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12.fitW) {
                Button(action: onExpand) {
                    HStack(spacing: 12.fitW) {
                        cover
                            .resizable().scaledToFill()
                            .frame(width: 44.fitW, height: 44.fitW)
                            .clipShape(RoundedRectangle(cornerRadius: 10.fitW))

                        VStack(alignment: .leading, spacing: 2.fitH) {
                            Text(title)
                                .font(.manropeSemiBold(size: 16.fitW))
                                .foregroundStyle(.white)
                            Text(subtitle)
                                .font(.manropeRegular(size: 13.fitW))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 14.fitW) {
                    Button(action: onPause) {
                        Image("playlistPauseIcon")
                            .frame(width: 32.fitW, height: 32.fitW)
                    }
                    .buttonStyle(.plain)

                    Button(action: onPlay) {
                        Image("NextIcon")
                            .frame(width: 32.fitW, height: 32.fitW)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 12.fitH)
            
            Rectangle()
                .fill(Color.blue.opacity(0.9))
                .frame(height: max(2 / UIScreen.main.scale, 1))
        }
        .background(.black191919)
        .padding(.horizontal, 8.fitW)
        .padding(.bottom, 4.fitH)
    }
}

#Preview {
    PlaylistView()
        .environmentObject(Router())
}
