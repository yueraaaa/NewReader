import SwiftUI
import NewReaderCore

struct SettingsView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var endpoint: String = ""
    @State private var apiKey: String = ""
    @State private var model: String = ""
    @State private var showSaved: Bool = false

    var body: some View {
        TabView {
            // AI Config
            VStack(alignment: .leading, spacing: 0) {
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Endpoint").font(.caption).foregroundStyle(.secondary)
                            TextField("https://api.openai.com/v1", text: $endpoint)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Key").font(.caption).foregroundStyle(.secondary)
                            SecureField("sk-…", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model").font(.caption).foregroundStyle(.secondary)
                            TextField("gpt-4o-mini", text: $model)
                                .textFieldStyle(.roundedBorder)
                        }
                    } header: {
                        Text("OpenAI 兼容 API").font(.headline)
                    } footer: {
                        Text("支持任何 OpenAI 兼容服务，如 OpenAI、Azure、DeepSeek、通义千问等。")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Section {
                        HStack {
                            Button("保存") {
                                // Validate endpoint is HTTPS before saving
                                let trimmed = endpoint.trimmingCharacters(in: .whitespaces)
                                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                                guard let url = URL(string: trimmed),
                                      url.scheme?.lowercased() == "https" else {
                                    viewModel.errorMessage = "API 端点必须使用 HTTPS"
                                    return
                                }
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
                                    .transition(.opacity)
                            }
                        }
                    }
                }
                .formStyle(.grouped)
            }
            .tabItem {
                Label("AI", systemImage: "brain.head.profile")
            }
            .onAppear {
                endpoint = viewModel.aiService.config.endpoint
                apiKey = viewModel.aiService.config.apiKey
                model = viewModel.aiService.config.model
            }

            // Cache
            VStack(alignment: .leading, spacing: 0) {
                Form {
                    Section {
                        LabeledContent("离线缓存大小") {
                            Text(viewModel.cacheSizeFormatted())
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("存储").font(.headline)
                    }

                    Section {
                        Button("清除所有缓存", role: .destructive) {
                            viewModel.clearCache()
                        }
                    }
                }
                .formStyle(.grouped)
            }
            .tabItem {
                Label("缓存", systemImage: "internaldrive")
            }

            // General
            VStack(alignment: .leading, spacing: 0) {
                Form {
                    Section {
                        LabeledContent("版本") {
                            Text("1.0.0").foregroundStyle(.secondary)
                        }
                        LabeledContent("订阅源") {
                            Text("\(viewModel.feeds.count)").foregroundStyle(.secondary)
                        }
                        LabeledContent("文章总数") {
                            Text("\(viewModel.feeds.flatMap { $0.articles }.count)")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("关于").font(.headline)
                    }
                }
                .formStyle(.grouped)
            }
            .tabItem {
                Label("通用", systemImage: "gearshape")
            }
        }
        .frame(width: 480, height: 340)
        .animation(.easeInOut(duration: 0.2), value: showSaved)
    }
}
