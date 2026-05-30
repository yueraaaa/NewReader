import SwiftUI
import NewReaderCore

struct SettingsView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var endpoint: String = ""
    @State private var apiKey: String = ""
    @State private var model: String = ""

    var body: some View {
        Form {
            Section("AI 配置") {
                TextField("API Endpoint", text: $endpoint)
                    .autocorrectionDisabled()
                SecureField("API Key", text: $apiKey)
                TextField("Model", text: $model)
                    .autocorrectionDisabled()
                Button("保存") {
                    viewModel.aiService.config.endpoint = endpoint
                    viewModel.aiService.config.apiKey = apiKey
                    viewModel.aiService.config.model = model
                    viewModel.aiService.saveConfig()
                }
            }

            Section("缓存") {
                HStack {
                    Text("离线缓存")
                    Spacer()
                    Text(viewModel.cacheSizeFormatted())
                        .foregroundStyle(.secondary)
                }
                Button("清除缓存", role: .destructive) {
                    viewModel.clearCache()
                }
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("订阅源")
                    Spacer()
                    Text("\(viewModel.feeds.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("文章")
                    Spacer()
                    Text("\(viewModel.feeds.flatMap { $0.articles }.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .onAppear {
            endpoint = viewModel.aiService.config.endpoint
            apiKey = viewModel.aiService.config.apiKey
            model = viewModel.aiService.config.model
        }
    }
}
