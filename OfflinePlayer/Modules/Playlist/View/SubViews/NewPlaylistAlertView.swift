import SwiftUI

struct NewPlaylistAlertView: View {

    @Binding var isPresented: Bool
    @Binding var text: String
    var onSave: (String) -> Void = { _ in }
    var onCancel: () -> Void = {}
    var title: String = "New playlist"

    @FocusState private var focus: Bool

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { }
            
            VStack(spacing: 0) {
                Text(title)
                    .font(.manropeSemiBold(size: 17.fitW))
                    .foregroundStyle(.white)
                    .padding(.top, 16.fitH)
                    .padding(.bottom, 12.fitH)

                TextField(
                    "",
                    text: $text,
                    prompt: Text("")
                        .font(.manropeRegular(size: 14.fitW))
                        .foregroundStyle(.white)
                )
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .focused($focus)
                .padding(.vertical, 10.fitH)
                .padding(.horizontal, 14.fitW)
                .background(
                    RoundedRectangle(cornerRadius: 18.fitW, style: .continuous)
                        .fill(.gray2C2C2C.opacity(0.8))
                )
                .foregroundStyle(.white)
                .padding(.horizontal, 16.fitW)

                Rectangle()
                    .fill(.gray707070)
                    .frame(width: 280, height: max(1 / UIScreen.main.scale, 0.5))
                    .padding(.top, 12.fitH)

                HStack(spacing: 0) {
                    Button {
                        onCancel()
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .font(.manropeSemiBold(size: 17.fitW))
                            .frame(maxWidth: .infinity, minHeight: 44.fitH)
                            .foregroundStyle(.blue)
                    }

                    Rectangle()
                        .fill(.gray707070)
                        .frame(width: max(1 / UIScreen.main.scale, 0.5), height: 40.fitH)

                    Button {
                        let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        onSave(name)
                        isPresented = false
                    } label: {
                        Text("Save")
                            .font(.manropeSemiBold(size: 17.fitW))
                            .frame(maxWidth: .infinity, minHeight: 44.fitH)
                            .foregroundStyle(canSave ? .blue : .gray)
                    }
                    .disabled(!canSave)
                }
            }
            .padding(.horizontal, 18.fitW)
            .padding(.vertical, 16.fitH)
            .frame(maxWidth: 280.fitW, maxHeight: 144.fitH)
            .background(
                RoundedRectangle(cornerRadius: 18.fitW, style: .continuous)
                    .fill(.gray353434)
            )
            .onAppear { focus = true }
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.18), value: isPresented)
    }
}

