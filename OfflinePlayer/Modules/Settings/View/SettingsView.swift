// MARK: - Models
import SwiftUI

enum SheetType: String, Identifiable {
    case rate, share, privacy, terms, feedback
    var id: String { rawValue }
}

struct SettingsRowData: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let sheet: SheetType
}

// MARK: - Screen

struct SettingsView: View {
    @EnvironmentObject private var router: Router
    
    @State private var activeSheet: SheetType?

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {

                    Text("Settings")
                        .font(.manropeBold(size: 24.fitW))
                        .foregroundStyle(.white)
                        .padding(.top, 8.fitH)
                        .padding(.bottom, 32.fitH)

                    // App
                    Text("App")
                        .font(.manropeRegular(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, 16.fitH)

                    SettingsCard(
                        rows: [
                            .init(icon: "starSettingsIcon",
                                  title: "Rate Us",
                                  subtitle: "Leave a review in the store",
                                  sheet: .rate),
                            .init(icon: "shareSettingsIcon",
                                  title: "Share with Friends",
                                  subtitle: "Send a link to download the app",
                                  sheet: .share)
                        ],
                        onTap: { activeSheet = $0 }
                    )

                    // Legal
                    Text("Legal")
                        .padding(.top, 24.fitH)
                        .padding(.bottom, 16.fitH)
                        .font(.manropeRegular(size: 18.fitW))
                        .foregroundStyle(.white.opacity(0.8))

                    SettingsCard(
                        rows: [
                            .init(icon: "lockSettingsIcon",
                                  title: "Privacy Policy",
                                  subtitle: "View how handle your data",
                                  sheet: .privacy),
                            .init(icon: "listSettingsIcon",
                                  title: "Terms of Use",
                                  subtitle: "Read our user agreement",
                                  sheet: .terms),
                            .init(icon: "messageSettingsIcon",
                                  title: "Share Feedback",
                                  subtitle: "Let us know what you think",
                                  sheet: .feedback)
                        ],
                        onTap: { activeSheet = $0 }
                    )
                }
                .padding(.horizontal, 20.fitW)
                .padding(.bottom, 40.fitH)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    // MARK: Sheet factory
    @ViewBuilder
    private func sheetView(for sheet: SheetType) -> some View {
        switch sheet {
        case .rate:
            RateUsSheet()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
        case .share:
            ShareWithFriendsSheet()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
        case .privacy:
            SafariView(url: URL(string: "https://www.google.com")!)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        case .terms:
            LegalSheet(title: "Terms of Use")
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        case .feedback:
            FeedbackSheet()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
        }
    }
}

// MARK: - Components

struct SettingsCard: View {
    let rows: [SettingsRowData]
    var onTap: (SheetType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                SettingsRow(
                    row: row,
                    showDivider: index < rows.count - 1,
                    onTap: onTap
                )
            }
        }
        .padding(.horizontal, 16.fitW)
        .padding(.vertical, 6.fitH)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.gray2C2C2C.opacity(0.8))
        )
    }
}

private struct SettingsRow: View {
    let row: SettingsRowData
    let showDivider: Bool
    var onTap: (SheetType) -> Void

    var body: some View {
        Button { onTap(row.sheet) } label: {
            HStack(spacing: 10.fitW) {
                Image("\(row.icon)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24.fitW, height: 24.fitW)

                VStack(alignment: .leading, spacing: 2.fitH) {
                    Text(row.title)
                        .foregroundStyle(.white)
                        .font(.manropeRegular(size: 16.fitW))
                    Text(row.subtitle)
                        .foregroundStyle(.gray707070)
                        .font(.manropeRegular(size: 14.fitW))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(height: 56.fitH)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SheetScaffold<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16.fitH) {
                Text(title)
                    .font(.manropeBold(size: 22))
                    .foregroundStyle(.white)
                content
                Spacer(minLength: 0)
            }
            .padding(20.fitW)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(Router())
}
