import SwiftUI
import NewReaderCore

struct SettingsView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var ttsEngine: TTSEngine = .apple
    @State private var ttsEndpoint: String = ""
    @State private var ttsApiKey: String = ""
    @State private var ttsVoiceId: String = "male-qn-qingse"
    @State private var ttsSpeed: Double = 1.0

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("AI 引擎")
                    Spacer()
                    Text("DeepSeek")
                        .foregroundStyle(.secondary)
                }
                Picker("模型", selection: Binding(
                    get: { viewModel.aiService.config.model },
                    set: { viewModel.aiService.config.model = $0; viewModel.aiService.saveConfig() }
                )) {
                    Text("DeepSeek-V3").tag("deepseek-chat")
                    Text("DeepSeek-R1").tag("deepseek-reasoner")
                }
            } header: {
                Text("AI 配置")
            } footer: {
                Text("AI 摘要和翻译由 NewReader 后端提供。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section("账户") {
                if viewModel.authService.isLoggedIn {
                    HStack {
                        Text("状态")
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("已登录")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Text("状态")
                        Spacer()
                        Text("未登录")
                            .foregroundStyle(.secondary)
                    }
                }
                Button(role: .destructive) {
                    Task { try? await viewModel.authService.signOut() }
                } label: {
                    Text(viewModel.authService.isLoggedIn ? "退出登录" : "登录")
                }
            }

            Section("外观") {
                Picker("", selection: $viewModel.appTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("缓存与同步") {
                HStack {
                    Text("离线缓存")
                    Spacer()
                    Text(viewModel.cacheSizeFormatted())
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("iCloud 同步")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.syncMonitor.isCloudSyncActive ? Color.green : Color.secondary)
                            .frame(width: 8, height: 8)
                        Text(viewModel.syncMonitor.isCloudSyncActive ? "已激活" : "未激活")
                            .foregroundStyle(.secondary)
                    }
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

                if ttsEngine == .custom {
                    TextField("Endpoint", text: $ttsEndpoint)
                        .autocorrectionDisabled()
                    SecureField("API Key", text: $ttsApiKey)
                    Picker("音色", selection: $ttsVoiceId) {
                        ForEach(CustomTTSConfig.voicePresets, id: \.id) { v in
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
                        var cfg = CustomTTSConfig.load()
                        cfg.endpoint = trimmed
                        cfg.apiKey = ttsApiKey
                        cfg.voiceId = ttsVoiceId
                        cfg.speed = ttsSpeed
                        cfg.save()
                        viewModel.ttsService.setEngine(.custom)
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
                    Text("\(viewModel.feeds.flatMap { $0.allArticles }.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .onAppear {
            let ttsCfg = CustomTTSConfig.load()
            ttsEngine = ttsCfg.engine
            ttsEndpoint = ttsCfg.endpoint
            ttsApiKey = ttsCfg.apiKey
            ttsVoiceId = ttsCfg.voiceId
            ttsSpeed = ttsCfg.speed
        }
    }
}
