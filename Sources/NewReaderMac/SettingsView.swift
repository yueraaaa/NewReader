import SwiftUI
import NewReaderCore

struct SettingsView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var provider: AIProvider = .openAI
    @State private var endpoint: String = ""
    @State private var apiKey: String = ""
    @State private var model: String = ""
    @State private var showSaved: Bool = false
    @State private var isTesting: Bool = false
    @State private var testError: String?
    @State private var ttsEngine: TTSEngine = .apple
    @State private var ttsEndpoint: String = ""
    @State private var ttsApiKey: String = ""
    @State private var ttsVoiceId: String = "male-qn-qingse"
    @State private var ttsSpeed: Double = 1.0
    @State private var isTestingTTS: Bool = false
    @State private var ttsTestError: String?
    @State private var selectedPage: SettingsPage = .ai


    enum SettingsPage: String, CaseIterable {
        case ai = "AI"
        case tts = "语音"
        case storage = "存储"
        case about = "关于"

        var icon: String {
            switch self {
            case .ai: return "brain.head.profile"
            case .tts: return "speaker.wave.2"
            case .storage: return "internaldrive"
            case .about: return "gearshape"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page selector
            Picker("", selection: $selectedPage) {
                ForEach(SettingsPage.allCases, id: \.self) { page in
                    Label(page.rawValue, systemImage: page.icon).tag(page)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Page content
            Group {
                switch selectedPage {
                case .ai:
                    aiPage
                case .tts:
                    ttsPage
                case .storage:
                    storagePage
                case .about:
                    aboutPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 460, height: 520)
        .onAppear {
            // Load non-sensitive config from disk only (no Keychain)
            provider = viewModel.aiService.config.provider
            endpoint = viewModel.aiService.config.endpoint
            model = viewModel.aiService.config.model
            let ttsCfg = MiniMaxTTSConfig.load()
            ttsEngine = ttsCfg.engine
            ttsEndpoint = ttsCfg.endpoint
            ttsApiKey = ttsCfg.apiKey
            ttsVoiceId = ttsCfg.voiceId
            ttsSpeed = ttsCfg.speed
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                if let sw = NSApp.windows.first(where: { $0.className.contains("Settings") }) {
                    sw.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    // MARK: - AI Page

    private var aiPage: some View {
        Form {
            Section {
                Picker("AI 服务商", selection: $provider) {
                    ForEach(AIProvider.allCases, id: \.self) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: provider) { _, newProvider in
                    endpoint = newProvider.defaultEndpoint
                    model = newProvider.defaultModel
                }
            } header: {
                Text("选择服务商").textCase(nil).font(.headline)
            } footer: {
                Text("选择 OpenAI 兼容（支持 DeepSeek、通义千问等）或 Anthropic（Claude 系列）。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("API Endpoint").font(.caption).foregroundStyle(.secondary)
                    TextField(provider.defaultEndpoint, text: $endpoint)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("API Key").font(.caption).foregroundStyle(.secondary)
                    SecureField(provider.apiKeyPlaceholder, text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Model").font(.caption).foregroundStyle(.secondary)
                    TextField(provider.defaultModel, text: $model)
                        .textFieldStyle(.roundedBorder)
                }
            } header: {
                Text("连接配置").textCase(nil).font(.headline)
            } footer: {
                Text(provider == .openAI
                     ? "支持 OpenAI、Azure、DeepSeek、通义千问等兼容服务。"
                     : "使用 Anthropic Messages API，支持 Claude 系列模型。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Button("测试连接") {
                            let trimmed = endpoint.trimmingCharacters(in: .whitespaces)
                                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                            viewModel.aiService.config.provider = provider
                            viewModel.aiService.config.endpoint = trimmed
                            viewModel.aiService.ensureConfigLoaded()
                            viewModel.aiService.config.apiKey = apiKey
                            viewModel.aiService.config.model = model

                            isTesting = true
                            testError = nil
                            Task {
                                testError = await viewModel.aiService.testConnection()
                                isTesting = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTesting)

                        if isTesting {
                            ProgressView().scaleEffect(0.7).frame(width: 16, height: 16)
                        }

                        Button("保存") {
                            let trimmed = endpoint.trimmingCharacters(in: .whitespaces)
                                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                            guard let url = URL(string: trimmed),
                                  url.scheme?.lowercased() == "https" else {
                                viewModel.errorMessage = "API 端点必须使用 HTTPS"
                                return
                            }
                            viewModel.aiService.config.provider = provider
                            viewModel.aiService.config.endpoint = trimmed
                            viewModel.aiService.ensureConfigLoaded()
                            viewModel.aiService.config.apiKey = apiKey
                            viewModel.aiService.config.model = model
                            viewModel.aiService.saveConfig()

                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSaved = false
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        if showSaved {
                            Label("已保存", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    if let err = testError {
                        if err.isEmpty {
                            Label("连接成功", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label(err, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }


    // MARK: - TTS Page

    private var ttsPage: some View {
        Form {
            Section {
                Picker("TTS 引擎", selection: $ttsEngine) {
                    ForEach(TTSEngine.allCases, id: \.self) { e in
                        Text(e.displayName).tag(e)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: ttsEngine) { _, newEngine in
                    viewModel.ttsService.setEngine(newEngine)
                }
            } header: {
                Text("语音引擎").textCase(nil).font(.headline)
            } footer: {
                Text(ttsEngine == .apple
                     ? "使用 macOS 内置语音引擎，离线可用。"
                     : "使用 MiniMax TTS API，需要网络连接，音质更自然。")
                    .font(.caption).foregroundStyle(.tertiary)
            }

            if ttsEngine == .minimax {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Endpoint").font(.caption).foregroundStyle(.secondary)
                        TextField("https://api.minimaxi.com/v1/t2a_v2", text: $ttsEndpoint)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        SecureField("输入 MiniMax API Key", text: $ttsApiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("音色").font(.caption).foregroundStyle(.secondary)
                        Picker("", selection: $ttsVoiceId) {
                            ForEach(MiniMaxTTSConfig.voicePresets, id: \.id) { v in
                                Text(v.name).tag(v.id)
                            }
                        }
                        .labelsHidden()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("语速: \(String(format: "%.1f", ttsSpeed))").font(.caption).foregroundStyle(.secondary)
                        Slider(value: $ttsSpeed, in: 0.5...2.0, step: 0.1)
                    }
                } header: {
                    Text("MiniMax 配置").textCase(nil).font(.headline)
                }

                Section {
                    HStack(spacing: 12) {
                        Button("测试朗读") {
                            isTestingTTS = true
                            ttsTestError = nil
                            // Build config directly from UI state, NOT from Keychain
                            var cfg = MiniMaxTTSConfig()
                            cfg.endpoint = ttsEndpoint.trimmingCharacters(in: .whitespaces)
                                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                            cfg.apiKey = ttsApiKey.trimmingCharacters(in: .whitespaces)
                            cfg.voiceId = ttsVoiceId
                            cfg.speed = ttsSpeed
                            let provider = MiniMaxTTSProvider(config: cfg)
                            Task {
                                let ok = await provider.speak("你好，这是 MiniMax 语音合成测试。")
                                ttsTestError = ok ? "" : (provider.errorMessage ?? "请求失败")
                                isTestingTTS = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTestingTTS)

                        if isTestingTTS {
                            ProgressView().scaleEffect(0.7)
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
                        .buttonStyle(.borderedProminent)
                    }

                    if let err = ttsTestError {
                        if err.isEmpty {
                            Label("朗读成功", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("请求失败，查看原始返回：", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                ScrollView {
                                    Text(err)
                                        .font(.system(size: 10, design: .monospaced))
                                        .textSelection(.enabled)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxHeight: 120)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Storage Page

    private var storagePage: some View {
        Form {
            Section {
                LabeledContent("离线缓存大小") {
                    Text(viewModel.cacheSizeFormatted())
                        .foregroundStyle(.secondary)
                }
                LabeledContent("iCloud 同步") {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.syncMonitor.isCloudSyncActive ? Color.green : Color.secondary)
                            .frame(width: 8, height: 8)
                        Text(viewModel.syncMonitor.isCloudSyncActive ? "已激活" : "未激活")
                            .foregroundStyle(.secondary)
                    }
                }
                if let containerID = viewModel.syncMonitor.configuredContainerID {
                    LabeledContent("容器") {
                        Text(containerID)
                            .font(.caption.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                }
                if let lastEvent = viewModel.syncMonitor.lastEvent {
                    LabeledContent("上次检测") {
                        Text(lastEvent, style: .relative)
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("存储").textCase(nil).font(.headline)
            } footer: {
                Text(viewModel.syncMonitor.accountState == .signedOut
                     ? "登录 iCloud 后自动开启跨设备同步。"
                     : "Feed 和文章自动通过 iCloud 同步至同一 Apple ID 的其他设备。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                Button("清除所有缓存", role: .destructive) {
                    viewModel.clearCache()
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Page

    private var aboutPage: some View {
        Form {
            Section {
                LabeledContent("版本") {
                    Text(AppVersion.short).foregroundStyle(.secondary)
                }
                LabeledContent("订阅源") {
                    Text("\(viewModel.feeds.count)").foregroundStyle(.secondary)
                }
                LabeledContent("文章总数") {
                    Text("\(viewModel.feeds.flatMap { $0.allArticles }.count)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("关于").textCase(nil).font(.headline)
            }
        }
        .formStyle(.grouped)
    }
}
