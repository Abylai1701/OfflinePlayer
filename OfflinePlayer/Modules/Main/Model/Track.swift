import SwiftUI

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let cover: Image
}
