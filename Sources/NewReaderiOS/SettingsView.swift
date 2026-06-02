import SwiftUI
import NewReaderCore

struct SettingsView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var provider: AIProvider = .openAI
    @State private var endpoint: String = ""
    @State private var apiKey: String = ""
    @State private var model: String = ""

    var body: some View {
        Form {
            Section("AI 服务商") {
                Picker("提供商", selection: $provider) {
                    ForEach(AIProvider.allCases, id: \.self) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: provider) { _, newProvider in
                    endpoint = newProvider.defaultEndpoint
                    model = newProvider.defaultModel
                }
            }

            Section("连接配置") {
                TextField("API Endpoint", text: $endpoint)
                    .autocorrectionDisabled()
                SecureField(provider.apiKeyPlaceholder, text: $apiKey)
                TextField("Model", text: $model)
                    .autocorrectionDisabled()
                Button("保存") {
                    let trimmed = endpoint.trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    guard let url = URL(string: trimmed),
                          url.scheme?.lowercased() == "https" else { return }
                    viewModel.aiService.config.provider = provider
                    viewModel.aiService.config.endpoint = trimmed
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
                    Text(AppVersion.short)
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
            provider = viewModel.aiService.config.provider
            endpoint = viewModel.aiService.config.endpoint
            apiKey = viewModel.aiService.config.apiKey
            model = viewModel.aiService.config.model
        }
    }
}
