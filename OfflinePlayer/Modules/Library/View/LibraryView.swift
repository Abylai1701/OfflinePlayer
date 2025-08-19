import SwiftUI

// MARK: - Model

struct LibraryTrack: Identifiable{
    let id = UUID()
    let title: String
    let artist: String
    let cover: Image
}

// MARK: - Screen

struct LibraryView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = LibraryViewModel()

    @State private var search = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8.fitW) {
                    Button { viewModel.back() } label: {
                        Image("backIcon")
                            .font(.system(size: 18.fitW, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 14.fitW, height: 28.fitH)
                            .contentShape(Rectangle())
                    }

                    Text("Search in Library")
                        .font(.manropeExtraBold(size: 24.fitW))
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom)

                ScrollView {
                    LibrarySearchView(searchText: search)
                        .padding(.bottom, 12.fitH)
                    
                    LazyVStack(spacing: 14.fitH) {
                        ForEach(viewModel.filtered(by: search)) { t in
                            LibraryTrackRow(
                                cover: t.cover,
                                title: t.title,
                                artist: t.artist,
                                onAdd: { viewModel.addToPlaylist(t) }
                            )
                            .padding(.horizontal, 16.fitW)
                        }
                    }
                    .padding(.bottom, 20.fitH)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.attach(router: router) }
    }
}

// MARK: - Components

private struct LibraryTrackRow: View {
    let cover: Image
    let title: String
    let artist: String
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12.fitW) {
            cover
                .resizable()
                .scaledToFill()
                .frame(width: 60.fitW, height: 60.fitW)
                .clipShape(RoundedRectangle(cornerRadius: 14.fitW, style: .continuous))

            VStack(alignment: .leading, spacing: 2.fitH) {
                Text(title)
                    .font(.manropeSemiBold(size: 14.fitW))
                    .foregroundStyle(.white)
                Text(artist)
                    .font(.manropeRegular(size: 12.fitW))
                    .foregroundStyle(.gray707070)
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.manropeSemiBold(size: 18.fitW))
                    .frame(width: 18.fitW, height: 18.fitW)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    LibraryView()
        .environmentObject(Router())
}
