import SwiftUI

struct PlaylistDetailsView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = PlaylistDetailsViewModel()
    @State private var sheetContentHeight: CGFloat = 430
    @State private var menuHeight: CGFloat = 260
    
    @State private var tracks: [Track] = [
        .init(title: "Fireproof Heart", artist: "Novaa",   cover: Image(.image)),
        .init(title: "Pretty", artist: "Inga Klaus", cover: Image(.image))
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: .zero) {
                HStack {
                    Button {
                        viewModel.back()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.manropeRegular(size: 18.fitW))
                            .foregroundStyle(.white)
                            .frame(width: 14.fitW, height: 28.fitW)
                    }
                    Spacer()
                    Button { viewModel.openMenu() } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20.fitW, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 18.fitW, height: 18.fitW)
                    }
                }
                .padding(.horizontal, 16.fitW)
                .padding(.top, 8.fitH)
                .padding(.bottom, 26.fitH)
                ScrollView {
                    // Big cover + play button
                    ZStack(alignment: .bottomTrailing) {
                        Image(.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 211.fitW, height: 211.fitH)
                            .clipShape(RoundedRectangle(cornerRadius: 24.fitW, style: .continuous))
                            .frame(alignment: .center)
                        
                        Button { /* play whole playlist */ } label: {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 56.fitW, height: 56.fitW)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 22.fitW, weight: .bold))
                                    .foregroundStyle(.black)
                                    .offset(x: 2.fitW)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, -14.fitW)
                        .padding(.bottom, -14.fitH)
                    }
                    .padding(.horizontal, 24.fitW)
                    .padding(.bottom, 10.fitH)
                    
                    // Title
                    Text("Party All Night")
                        .font(.manropeExtraBold(size: 24.fitW))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10.fitH)
                        .padding(.bottom, 32.fitH)
                    
                    // Action tiles
                    VStack(spacing: 14.fitH) {
                        ActionTile(
                            icon: "playlistFileIcon",
                            title: "Import from Device",
                            onTap: { /* import action */ }
                        )
                        ActionTile(
                            icon: "playlistMusicIcon",
                            title: "Search in Library",
                            onTap: { viewModel.pushToLibrary() }
                        )
                    }
                    .padding(.horizontal, 16.fitW)
                    .padding(.top, 4.fitH)
                    .padding(.bottom, 14.fitH)
                    
                    // Tracks
                    VStack(spacing: 14.fitH) {
                        ForEach(tracks) { t in
                            PlaylistTrackRow(
                                cover: t.cover,
                                title: t.title,
                                artist: t.artist,
                                onMenuTap: { viewModel.openActions(for: t) }
                            )
                        }
                    }
                    .padding(.horizontal, 16.fitW)
                    
                    Spacer(minLength: 120.fitH) // место под мини-плеер/табар
                }
            }
            .task {
                viewModel.attach(router: router)
            }
//            .sheet(isPresented: $viewModel.isActionSheetPresented) {
//                if let t = viewModel.actionTrack {
//                    TrackActionsSheet(
//                        track: t,
//                        onLike: { viewModel.like(); viewModel.closeActions() },
//                        onAddToPlaylist: { viewModel.addToPlaylist(); viewModel.closeActions() },
//                        onPlayNext: { viewModel.playNext(); viewModel.closeActions() },
//                        onDownload: { viewModel.download(); viewModel.closeActions() },
//                        onShare: { viewModel.share(); viewModel.closeActions() },
//                        onGoToAlbum: { viewModel.goToAlbum(); viewModel.closeActions() },
//                        onRemove: { viewModel.remove(); viewModel.closeActions() }
//                    )
//                    .presentationDetents([.height(462)])
//                    .presentationCornerRadius(28.fitW)
//                    .presentationDragIndicator(.hidden)
//                    .ignoresSafeArea()
//                }
//            }
            .overlay {
                Color.black
                    .opacity(viewModel.isShowMenuTapped ? 0.35 : 0)
                    .ignoresSafeArea()
            }
            .animation(.easeInOut(duration: viewModel.isShowMenuTapped ? 0.2 : 0.001), value: viewModel.isShowMenuTapped)
        }
//        
//        .sheet(isPresented: $viewModel.isShowMenuTapped) {
//            PlaylistActionsSheet(
//                onShare: {},
//                onRename: {},
//                onAddTrack: {},
//                onDelete: {}
//            )
//            .presentationDetents([.height(234)])
//            .presentationCornerRadius(28.fitW)
//            .presentationDragIndicator(.hidden)
//            .ignoresSafeArea()
//        }
//        .onTapGesture {
//            UIApplication.shared.endEditing(true)
//        }
//        .scrollIndicators(.hidden)
//        .blur(radius: viewModel.isShowMenuTapped || viewModel.isActionSheetPresented ? 20 : 0)
//        .animation(.easeInOut(duration: 0.3), value: viewModel.isShowMenuTapped)
//        .animation(.easeInOut(duration: 0.3), value: viewModel.isActionSheetPresented)
//        .toolbar(.hidden, for: .navigationBar)
//        .background {
//            LinearGradient(colors: [.gray222222, .black111111],
//                           startPoint: .top, endPoint: .bottom)
//            .ignoresSafeArea()
//        }
    }
    private var sheetHeightClamped: CGFloat {
        let screenH = UIScreen.main.bounds.height
        return min(sheetContentHeight, screenH * 0.9)
    }
}



// MARK: - Components
private struct ActionTile: View {
    let icon: String
    let title: String
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10.fitW) {
                RoundedRectangle(cornerRadius: 16.fitW, style: .continuous)
                    .fill(.gray2C2C2C)
                    .frame(width: 60.fitW, height: 60.fitW)
                    .overlay {
                        Image(icon)
                            .font(.system(size: 28.fitW, weight: .semibold))
                            .foregroundStyle(.grayB3B3B3)
                    }
                
                Text(title)
                    .font(.manropeSemiBold(size: 14.fitW))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableRowStyle())
    }
}

private struct PlaylistTrackRow: View {
    let cover: Image
    let title: String
    let artist: String
    var onMenuTap: () -> Void
    
    var body: some View {
        HStack(spacing: 10.fitW) {
            cover
                .resizable()
                .scaledToFill()
                .frame(width: 60.fitW, height: 60.fitW)
                .clipShape(RoundedRectangle(cornerRadius: 16.fitW, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2.fitH) {
                Text(title)
                    .font(.manropeSemiBold(size: 14.fitW))
                    .foregroundStyle(.white)
                Text(artist)
                    .font(.manropeRegular(size: 12.fitW))
                    .foregroundStyle(.gray707070)
            }
            
            Spacer()
            
            Button(action: onMenuTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18.fitW, weight: .semibold))
                    .foregroundStyle(.grayB3B3B3)
                    .frame(width: 18.fitW, height: 18.fitW)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    PlaylistDetailsView()
        .environmentObject(Router())
}
