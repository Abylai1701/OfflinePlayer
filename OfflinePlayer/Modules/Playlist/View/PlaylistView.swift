import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = PlaylistViewModel()
    
    @State private var search = ""
    @State private var showNewPlaylistAlert = false
    @State private var newPlaylistName = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: .zero) {
                
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
                        PlaylistRow(cover: Image(.image),
                                    title: "Favorites",
                                    subtitle: "456 tracks",
                                    onTap: {viewModel.pushToDetail()})
                        PlaylistRow(cover: Image(.image),
                                    title: "Party All Night",
                                    subtitle: "50 tracks",
                                    onTap: {viewModel.pushToDetail()})
                        PlaylistRow(cover: Image(.image),
                                    title: "Party All Night",
                                    subtitle: "78 tracks",
                                    onTap: {viewModel.pushToDetail()})
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
                onExpand: {}, onPlay: {},
                onPause: {}
            )
        }
        .overlay {
            if showNewPlaylistAlert {
                NewPlaylistAlertView(
                    isPresented: $showNewPlaylistAlert,
                    text: $newPlaylistName,
                    onSave: {_ in },
                    onCancel: {}
                )
//                .zIndex(10)
            }
        }
        .task {
            viewModel.attach(router: router)
        }
        .onTapGesture {
            UIApplication.shared.endEditing(true)
        }
    }
}

// MARK: - Rows

private struct NewPlaylistRow: View {
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10.fitW) {
                RoundedRectangle(cornerRadius: 16.fitW, style: .continuous)
                    .fill(.gray2C2C2C)
                    .frame(width: 60.fitW, height: 60.fitW)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.manropeSemiBold(size: 22.fitW))
                            .frame(width: 18.fitW, height: 18.fitW)
                            .foregroundStyle(.gray707070)
                    }
                
                Text("New Playlist")
                    .font(.manropeSemiBold(size: 14.fitW))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableRowStyle())
    }
}

struct PlaylistRow: View {
    let cover: Image
    let title: String
    let subtitle: String
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10.fitW) {
                cover.resizable().scaledToFill()
                    .frame(width: 60.fitW, height: 60.fitW)
                    .clipShape(RoundedRectangle(cornerRadius: 16.fitW, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2.fitH) {
                    Text(title)
                        .font(.manropeSemiBold(size: 14.fitW))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.manropeRegular(size: 12.fitW))
                        .foregroundStyle(.gray707070)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18.fitW, weight: .semibold))
                    .frame(width: 18.fitW, height: 18.fitW)
                    .foregroundStyle(.white)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableRowStyle())
    }
}

// MARK: - Mini Player

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
                        Image("playlistNextIcon")
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


struct PressableRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16.fitW, style: .continuous)
                    .fill(.white.opacity(configuration.isPressed ? 0.08 : 0))
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    PlaylistView()
        .environmentObject(Router())
}
