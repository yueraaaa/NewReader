import SwiftUI
import NewReaderCore

/// In-window overlay for adding a new feed subscription
struct SubscribeOverlayView: View {
    @EnvironmentObject var viewModel: ReaderViewModel

    @State private var urlString: String = ""
    @State private var isSubscribing: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("添加订阅")
                .font(.headline)

            TextField("输入或粘贴 RSS / Atom Feed 地址…", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .frame(width: 360)
                .focused($isFocused)
                .disabled(isSubscribing)
                .onSubmit { subscribe() }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                Button("取消") {
                    viewModel.showSubscribe = false
                }
                .keyboardShortcut(.escape)

                Button(action: subscribe) {
                    if isSubscribing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    }
                    Text("订阅")
                }
                .keyboardShortcut(.return)
                .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty || isSubscribing)
            }
        }
        .padding(30)
        .frame(width: 420, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 5)
        )
        .onAppear {
            // Brief delay so the TextField is in the view hierarchy before focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }

    private func subscribe() {
        guard !urlString.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            isSubscribing = true
            viewModel.errorMessage = nil
            await viewModel.subscribe(url: urlString)
            isSubscribing = false
            if viewModel.errorMessage == nil {
                viewModel.showSubscribe = false
            }
        }
    }
}
