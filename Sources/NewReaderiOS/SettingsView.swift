import SwiftUI
import NewReaderCore

struct SettingsView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var provider: AIProvider = .openAI
    @State private var endpoint: String = ""
    @State private var apiKey: String = ""
    @State private var model: String = ""
    @State private var ttsEngine: TTSEngine = .apple
    @State private var ttsEndpoint: String = ""
    @State private var ttsApiKey: String = ""
    @State private var ttsVoiceId: String = "male-qn-qingse"
    @State private var ttsSpeed: Double = 1.0

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


            Section("语音") {
                Picker("引擎", selection: $ttsEngine) {
                    ForEach(TTSEngine.allCases, id: \.self) { e in
                        Text(e.displayName).tag(e)
                    }
                }
                .onChange(of: ttsEngine) { _, e in
                    viewModel.ttsService.setEngine(e)
                }

                if ttsEngine == .minimax {
                    TextField("Endpoint", text: $ttsEndpoint)
                        .autocorrectionDisabled()
                    SecureField("API Key", text: $ttsApiKey)
                    Picker("音色", selection: $ttsVoiceId) {
                        ForEach(MiniMaxTTSConfig.voicePresets, id: \.id) { v in
                            Text(v.name).tag(v.id)
                        }
                    }
                    HStack {
                        Text("语速")
                        Slider(value: $ttsSpeed, in: 0.5...2.0, step: 0.1)
                    }
                    Button("保存") {
                        let trimmed = ttsEndpoint.trimmingCharacters(in: .whitespaces)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                        var cfg = MiniMaxTTSConfig.load()
                        cfg.endpoint = trimmed
                        cfg.apiKey = ttsApiKey
                        cfg.voiceId = ttsVoiceId
                        cfg.speed = ttsSpeed
                        cfg.save()
                        viewModel.ttsService.setEngine(.minimax)
                    }
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
            viewModel.aiService.ensureConfigLoaded()
            provider = viewModel.aiService.config.provider
            endpoint = viewModel.aiService.config.endpoint
            apiKey = viewModel.aiService.config.apiKey
            model = viewModel.aiService.config.model
            let ttsCfg = MiniMaxTTSConfig.load()
            ttsEngine = ttsCfg.engine
            ttsEndpoint = ttsCfg.endpoint
            ttsApiKey = ttsCfg.apiKey
            ttsVoiceId = ttsCfg.voiceId
            ttsSpeed = ttsCfg.speed
        }
    }
}
