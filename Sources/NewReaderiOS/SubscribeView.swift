import SwiftUI
import NewReaderCore

struct SubscribeView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @Environment(\.dismiss) var dismiss

    @State private var urlString: String = ""
    @State private var isSubscribing: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("输入 RSS/Atom Feed 地址", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    
                    .padding(.horizontal)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        isSubscribing = true
                        viewModel.errorMessage = nil
                        await viewModel.subscribe(url: urlString)
                        isSubscribing = false
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if isSubscribing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("订阅")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty || isSubscribing)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("添加订阅")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
