import SwiftUI
import NewReaderCore

struct SettingsView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var provider: AIProvider = .openAI
    @State private var endpoint: String = ""
    @State private var apiKey: String = ""
    @State private var model: String = ""
    @State private var showSaved: Bool = false
    @State private var selectedPage: SettingsPage = .ai

    enum SettingsPage: String, CaseIterable {
        case ai = "AI"
        case storage = "存储"
        case about = "关于"

        var icon: String {
            switch self {
            case .ai: return "brain.head.profile"
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
                case .storage:
                    storagePage
                case .about:
                    aboutPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 440, height: 380)
        .onAppear {
            provider = viewModel.aiService.config.provider
            endpoint = viewModel.aiService.config.endpoint
            apiKey = viewModel.aiService.config.apiKey
            model = viewModel.aiService.config.model
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
                HStack(spacing: 12) {
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
            } header: {
                Text("存储").textCase(nil).font(.headline)
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
                    Text("1.0.1").foregroundStyle(.secondary)
                }
                LabeledContent("订阅源") {
                    Text("\(viewModel.feeds.count)").foregroundStyle(.secondary)
                }
                LabeledContent("文章总数") {
                    Text("\(viewModel.feeds.flatMap { $0.articles }.count)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("关于").textCase(nil).font(.headline)
            }
        }
        .formStyle(.grouped)
    }
}
