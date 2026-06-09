import SwiftUI
import NewReaderCore

struct WorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ReaderViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("阅读工作台", systemImage: "sparkles")
                    .font(.title2.weight(.semibold))
                Spacer()

                if viewModel.isGeneratingWorkspace == true {
                    ProgressView().scaleEffect(0.7).padding(.trailing, 4)
                    Text("分析中…").font(.caption).foregroundStyle(.secondary)
                }

                Button {
                    Task { await viewModel.generateWorkspace() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("重新生成分析")
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(viewModel.isGeneratingWorkspace == true)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14)).foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain).help("关闭 (Esc)").keyboardShortcut(.escape)
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)

            Divider().padding(.horizontal, 20)

            if let snap = viewModel.workspace {
                workspaceContent(snap)
            } else {
                emptyState
            }
        }
        .frame(width: 640, height: 560)
        .background(.regularMaterial)
        .onAppear { loadSnapshotIfStale() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles").font(.system(size: 40)).foregroundStyle(.quaternary)
            if let msg = viewModel.workspaceStatusMessage {
                        Text(msg).font(.callout).foregroundStyle(.orange).multilineTextAlignment(.center)
                    } else {
                        Text("暂无分析数据").font(.title3).foregroundStyle(.secondary)
                    }
            Text("阅读 5 篇以上文章后，AI 会自动生成\n关键词关联图和阅读兴趣总结")
                .font(.callout).foregroundStyle(.tertiary).multilineTextAlignment(.center)
            Button("立即生成") { Task { await viewModel.generateWorkspace() } }
                .buttonStyle(.borderedProminent).padding(.top, 8)
            Spacer()
        }
    }

    private func workspaceContent(_ snap: WorkspaceSnapshot) -> some View {
        VStack(spacing: 16) {
            // AI summary
            if let msg = viewModel.workspaceStatusMessage {
                    Text(msg).font(.callout).foregroundStyle(.orange).padding(.horizontal, 20).padding(.top, 12)
                }
                if !snap.summaryText.isEmpty {
                Text(snap.summaryText)
                    .font(.callout).foregroundStyle(.primary)
                    .padding(.horizontal, 20).padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Graph
            GraphCanvasView(keywords: snap.keywords, relations: snap.relations)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
                .frame(height: 280)

            // Keyword tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(snap.keywords, id: \.self) { kw in
                        Text(kw).font(.caption.weight(.medium))
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(.quaternary, in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)

            // Footer
            HStack {
                Text("基于 \(snap.articleCount) 篇文章").font(.caption).foregroundStyle(.tertiary)
                Spacer()
                Text(snap.createdAt, style: .relative).font(.caption).foregroundStyle(.tertiary)
                Text("前生成").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20).padding(.bottom, 12)
        }
    }

    private func loadSnapshotIfStale() {
        guard let snap = viewModel.workspace else { return }
        // Auto-refresh if older than 24 hours
        if snap.createdAt.timeIntervalSinceNow < -24 * 3600 {
            Task { await viewModel.generateWorkspace() }
        }
    }
}
