import SwiftUI
import Kingfisher

struct PlaylistDetailsView: View {
    @EnvironmentObject private var router: Router
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: PlaylistDetailsViewModel
    @State private var sheetContentHeight: CGFloat = 430
    @State private var menuHeight: CGFloat = 260
    
    init(tracks: [MyTrack], playlist: MyPlaylist, isLocalPlaylist: Bool = false) {
        _viewModel = StateObject(wrappedValue: PlaylistDetailsViewModel(tracks: tracks, playlist: playlist))
    }
    
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
                    ZStack(alignment: .bottomTrailing) {
                        KFImage(viewModel.playlist.artworkURL)
                            .placeholder {
                                Color.gray.opacity(0.2)
                            }
                            .cacheOriginalImage()
                            .loadDiskFileSynchronously()
                            .resizable()
                            .scaledToFill()
                            .frame(width: 211.fitW, height: 211.fitW)
                            .clipShape(RoundedRectangle(cornerRadius: 24.fitW, style: .continuous))
                        
                        Button {
                            Task {
                                viewModel.play()
                            }
                        } label: {
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
                    
                    Text(viewModel.playlist.playlistName)
                        .font(.manropeExtraBold(size: 24.fitW))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10.fitH)
                        .padding(.bottom, 32.fitH)
                    
                    VStack(spacing: 14.fitH) {
                        ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { idx, t in
                            PlaylistTrackRow(
                                coverURL: t.artworkURL,
                                title: t.title,
                                artist: t.artist,
                                onMenuTap: { viewModel.openActions(for: t) }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.play(startAt: idx)
                            }
                        }
                    }
                    .padding(.horizontal, 16.fitW)
                    
                    
                    Spacer(minLength: 120.fitH)
                }
            }
            .task {
                viewModel.attach(router: router)
                viewModel.bindIfNeeded(context: modelContext)
                if viewModel.tracks.isEmpty {
                    await viewModel.refresh()
                }
            }
            .sheet(isPresented: $viewModel.isActionSheetPresented) {
                if let t = viewModel.actionTrack {
                    TrackActionsSheet(
                        isLocal: false,
                        track: t,
                        onLike: {
                            viewModel.isActionSheetPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                viewModel.addCurrentTrackToFavorites()
                            }
                        },
                        
                        onPlayNext: {
                            viewModel.playNext();
                            viewModel.closeActions() },
                        
                        onDownload: {
                            viewModel.download(t);
                            viewModel.closeActions() },
                        
                        onShare: {
                            viewModel.closeActions()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                viewModel.shareCurrentTrack()
                            }
                        },
                        
                        onRemove: {}
                    )
                    .presentationDetents([.height(290)])
                    .presentationCornerRadius(28.fitW)
                    .presentationDragIndicator(.hidden)
                    .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $viewModel.isShareSheetPresented) {
                ShareSheet(items: viewModel.shareItems)
            }
            .overlay {
                Color.black
                    .opacity(viewModel.isShowMenuTapped ? 0.35 : 0)
                    .ignoresSafeArea()
            }
            .animation(.easeInOut(duration: viewModel.isShowMenuTapped ? 0.2 : 0.001), value: viewModel.isShowMenuTapped)
        }
        
        .sheet(isPresented: $viewModel.isShowMenuTapped) {
            PlaylistActionsSheet(
                isLocal: false,
                onShare: {
                    viewModel.isShowMenuTapped = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        viewModel.sharePlaylist()
                    }
                },
                onRename: {},
                onAddTrack: {},
                onDelete: {}
            )
            .presentationDetents([.height(64)])
            .presentationCornerRadius(28.fitW)
            .presentationDragIndicator(.hidden)
            .ignoresSafeArea()
        }
        .onTapGesture {
            UIApplication.shared.endEditing(true)
        }
        .scrollIndicators(.hidden)
        .blur(radius: viewModel.isShowMenuTapped || viewModel.isActionSheetPresented ? 20 : 0)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isShowMenuTapped)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isActionSheetPresented)
        .toolbar(.hidden, for: .navigationBar)
        .background {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
    }
    private var sheetHeightClamped: CGFloat {
        let screenH = UIScreen.main.bounds.height
        return min(sheetContentHeight, screenH * 0.9)
    }
}



// MARK: - Components
struct ActionTile: View {
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
        .buttonStyle(.plain)
    }
}

struct PlaylistTrackRow: View {
    let coverURL: URL?
    let title: String
    let artist: String
    var onMenuTap: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 10.fitW) {
            KFImage(coverURL)
                .placeholder { Color.gray.opacity(0.2) }
                .cacheOriginalImage()
                .loadDiskFileSynchronously()
                .resizable()
                .scaledToFill()
                .frame(width: 60.fitW, height: 60.fitW)
                .clipShape(RoundedRectangle(cornerRadius: 16.fitW, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2.fitH) {
                Text(title).font(.manropeSemiBold(size: 14.fitW)).foregroundStyle(.white)
                Text(artist).font(.manropeRegular(size: 12.fitW)).foregroundStyle(.gray707070)
            }
            Spacer()
            Button(action: onMenuTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18.fitW, weight: .semibold))
                    .foregroundStyle(.grayB3B3B3)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}
