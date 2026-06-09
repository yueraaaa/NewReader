import SwiftUI
import NewReaderCore

struct WorkspaceView: View {
    @EnvironmentObject var viewModel: ReaderViewModel

    var body: some View {
        Group {
            if let snap = viewModel.workspace {
                workspaceContent(snap)
            } else {
                emptyState
            }
        }
        .navigationTitle("阅读工作台")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.generateWorkspace() }
                } label: {
                    if viewModel.isGeneratingWorkspace == true {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isGeneratingWorkspace == true)
            }
        }
        .onAppear { loadSnapshotIfStale() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles").font(.system(size: 48)).foregroundStyle(.quaternary)
            Text("暂无分析数据").font(.title3.weight(.medium)).foregroundStyle(.secondary)
            Text("阅读 5 篇以上文章后，AI 会自动生成\n关键词关联图和阅读兴趣总结")
                .font(.callout).foregroundStyle(.tertiary).multilineTextAlignment(.center)
            Button("立即生成") { Task { await viewModel.generateWorkspace() } }
                .buttonStyle(.borderedProminent).padding(.top, 8)
            Spacer()
        }
    }

    private func workspaceContent(_ snap: WorkspaceSnapshot) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // AI summary
                if let msg = viewModel.workspaceStatusMessage {
                    Text(msg).font(.callout).foregroundStyle(.orange).padding(.horizontal, 20).padding(.top, 12)
                }
                if !snap.summaryText.isEmpty {
                    Text(snap.summaryText)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                // Graph
                GraphCanvasView(keywords: snap.keywords, relations: snap.relations)
                    .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                    .frame(height: 280)
                    .padding(.horizontal, 16)

                // Keyword tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(snap.keywords, id: \.self) { kw in
                            Text(kw)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Footer
                HStack {
                    Text("基于 \(snap.articleCount) 篇文章")
                        .font(.caption2).foregroundStyle(.tertiary)
                    Spacer()
                    Text(snap.createdAt, style: .relative)
                        .font(.caption2).foregroundStyle(.tertiary)
                    Text("前生成")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func loadSnapshotIfStale() {
        guard let snap = viewModel.workspace else { return }
        if snap.createdAt.timeIntervalSinceNow < -24 * 3600 {
            Task { await viewModel.generateWorkspace() }
        }
    }
}
