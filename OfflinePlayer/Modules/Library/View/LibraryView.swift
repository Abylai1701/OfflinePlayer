import SwiftUI
import SwiftData

struct LibraryView: View {
    
    // MARK: - Properties

    @EnvironmentObject private var router: Router
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: LibraryViewModel
    @State private var search = ""
    
    // MARK: - Init

    init(playlist: LocalPlaylist) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(playlist: playlist))
    }
    
    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    LibrarySearchView(searchText: $search)
                        .onChange(of: search) { _, newValue in
                            viewModel.query = newValue
                            viewModel.onQueryChanged()
                        }
                        .padding(.bottom, 12.fitH)
                    
                    if viewModel.isLoading {
                        ProgressView().controlSize(.large).padding(.top, 40)
                    } else if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.grayB3B3B3)
                            .padding(.top, 24)
                    } else if viewModel.results.isEmpty, !search.isEmpty {
                        Text("Nothing found")
                            .font(.footnote)
                            .foregroundStyle(.grayB3B3B3)
                            .padding(.top, 24)
                    } else {
                        LazyVStack(spacing: 14.fitH) {
                            ForEach(viewModel.results, id: \.id) { t in
                                APISearchTrackRow(
                                    coverURL: t.artworkURL,
                                    title: t.title,
                                    artist: t.artist,
                                    onAdd: { viewModel.addToPlaylist(t) }
                                )
                                .padding(.horizontal, 16.fitW)
                            }
                        }
                        .padding(.bottom, 20.fitH)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.attach(router: router)
            viewModel.bindIfNeeded(context: modelContext)
            viewModel.query = "a"
            viewModel.onQueryChanged()
        }
    }
    
    private var header: some View {
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
    }
}
