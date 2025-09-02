//
//  LocalPlaylistDetailView.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 23.08.2025.
//

import Foundation
import SwiftUI
import Kingfisher
import PhotosUI
import UniformTypeIdentifiers

struct LocalPlaylistDetailView: View {
    @EnvironmentObject private var router: Router
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: LocalPlaylistDetailViewModel
    @State private var sheetContentHeight: CGFloat = 430
    @State private var menuHeight: CGFloat = 260
    
    @State private var photoItem: PhotosPickerItem?
    @State private var playlistName = ""
    
    @State private var isFileImporterPresented = false
    
    init(playlist: LocalPlaylist) {
        _viewModel = StateObject(wrappedValue: LocalPlaylistDetailViewModel(playlist: playlist))
    }
    
    var body: some View {
        content
            .sheet(isPresented: $viewModel.isShowMenuTapped) {
                if viewModel.isProtected {
                    PlaylistActionsSheetForFavorites {
                        viewModel.isShowMenuTapped = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.pushToLibrary()
                        }
                    }
                    .presentationDetents([.height(64)])
                    .presentationCornerRadius(28.fitW)
                    .presentationDragIndicator(.hidden)
                    .ignoresSafeArea()
                } else {
                    PlaylistActionsSheet(
                        isLocal: true,
                        onShare: {
                            viewModel.isShowMenuTapped = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.sharePlaylist()
                            }
                        },
                        onRename: {
                            viewModel.isShowMenuTapped = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.isRenameSheetPresented = true
                            }
                        },
                        onAddTrack: {
                            viewModel.isShowMenuTapped = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.pushToLibrary()
                            }
                        },
                        onDelete: {
                            viewModel.isShowMenuTapped = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                Task {
                                    await viewModel.deletePlaylist()
                                }
                            }
                        }
                    )
                    .presentationDetents([.height(234)])
                    .presentationCornerRadius(28.fitW)
                    .presentationDragIndicator(.hidden)
                    .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $viewModel.isShareSheetPresented) {
                ShareSheet(items: viewModel.shareItems)
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    viewModel.importLocalFiles(urls: urls)
                case .failure(let error):
                    print("Import error:", error.localizedDescription)
                }
            }
            .onTapGesture {
                UIApplication.shared.endEditing(true)
            }
            .scrollIndicators(.hidden)
            .blur(radius: viewModel.isShowMenuTapped || viewModel.isActionSheetPresented ? 20 : 0)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isShowMenuTapped)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isActionSheetPresented)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isRenameSheetPresented)
            .overlay {
                if viewModel.isRenameSheetPresented {
                    NewPlaylistAlertView(
                        isPresented: $viewModel.isRenameSheetPresented,
                        text: $playlistName,
                        onSave: { name in
                            viewModel.playlist.title = name
                        },
                        onCancel: {
                            viewModel.isRenameSheetPresented = false
                        },
                        title: "New name"
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .background {
                LinearGradient(colors: [.gray222222, .black111111],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, newItem in
                guard let item = newItem else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        viewModel.updateArtwork(with: data)
                    }
                }
            }
    }
    
    private var content: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: .zero) {
                
                navBar
                    .padding(.horizontal, 16.fitW)
                    .padding(.top, 8.fitH)
                    .padding(.bottom, 26.fitH)
                scrollView
            }
            .task {
                viewModel.attach(router: router)
            }
            .onAppear {
                viewModel.bindIfNeeded(context: modelContext)
            }
            .sheet(isPresented: $viewModel.isActionSheetPresented) {
                if let t = viewModel.localActionTrack {
                    if viewModel.isProtected {
                        LocalTrackActionsSheet(
                            isFavorite: true,
                            title: t.title,
                            artist: t.artist,
                            coverURL: URL(string: t.artworkURLString ?? ""),
                            onLike: { },
                            onPlayNext: { },
                            onDownload: { },
                            onShare: {
                                viewModel.isActionSheetPresented = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    viewModel.shareLocalTrack()
                                }
                            },
                            onRemove: {
                                viewModel.isActionSheetPresented = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    viewModel.remove()
                                }
                            }
                        )
                        .presentationDetents([.height(290)])
                        .presentationCornerRadius(28.fitW)
                        .presentationDragIndicator(.hidden)
                        .ignoresSafeArea()
                    } else {
                        LocalTrackActionsSheet(
                            isFavorite: false,
                            title: t.title,
                            artist: t.artist,
                            coverURL: URL(string: t.artworkURLString ?? ""),
                            onLike: {
                                viewModel.isActionSheetPresented = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    viewModel.addCurrentTrackToFavorites()
                                }
                            },
                            onPlayNext: { },
                            onDownload: { },
                            onShare: {
                                viewModel.isActionSheetPresented = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    viewModel.shareLocalTrack()
                                }
                            },
                            onRemove: {
                                viewModel.isActionSheetPresented = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    viewModel.remove()
                                }
                            }
                        )
                        .presentationDetents([.height(340)])
                        .presentationCornerRadius(28.fitW)
                        .presentationDragIndicator(.hidden)
                        .ignoresSafeArea()
                    }
                }
            }
            .overlay {
                Color.black
                    .opacity(viewModel.isShowMenuTapped ? 0.35 : 0)
                    .ignoresSafeArea()
            }
            .animation(.easeInOut(duration: viewModel.isShowMenuTapped ? 0.2 : 0.001), value: viewModel.isShowMenuTapped)
        }
    }
    
    private var navBar: some View {
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
            
            Button {
                viewModel.openMenu()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20.fitW, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 18.fitW, height: 18.fitW)
            }
        }
    }
    
    private var scrollView: some View {
        ScrollView {
            ZStack(alignment: .bottomTrailing) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    coverView
                        .frame(width: 211.fitW, height: 211.fitW)
                        .clipShape(RoundedRectangle(cornerRadius: 24.fitW, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Button {
                    Task {
                        await viewModel.play()
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
            
            Text(viewModel.playlist.title)
                .font(.manropeExtraBold(size: 24.fitW))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 10.fitH)
                .padding(.bottom, 32.fitH)
            
            VStack(spacing: 14.fitH) {
                ActionTile(
                    icon: "playlistFileIcon",
                    title: "Import from Device",
                    onTap: {
                        isFileImporterPresented = true
                    }
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
            
            VStack(spacing: 14.fitH) {
                ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { idx, row in
                    PlaylistTrackRow(
                        coverURL: row.remoteArtworkURL,
                        title: row.title,
                        artist: row.artist,
                        onMenuTap: {
                            if let item = viewModel.items.first(where: { $0.id == row.id }) {
                                viewModel.openActions(for: item)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await viewModel.play(startAt: idx)
                        }
                    }
                }
            }
            .padding(.horizontal, 16.fitW)
            
            
            Spacer(minLength: 120.fitH)
        }
    }
    
    @ViewBuilder
    private var coverView: some View {
        if let data = viewModel.playlist.artworkData,
           let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            Image(.emptyPhoto)
                .resizable()
                .scaledToFill()
        }
    }
}
