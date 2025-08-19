import SwiftUI

struct Playlist: Identifiable {
    let id: UUID
    let name: String
    let cover: Image
    let tracks: [Track]
}
