import SwiftUI

// MARK: - Mutable graph node for force layout

private struct LayoutNode: Identifiable {
    let id: String
    let keyword: String
    var x: CGFloat
    var y: CGFloat
    var pinned: Bool = false
}

// MARK: - Shared force-directed keyword graph canvas

/// A reusable force-directed graph view showing keyword relationships.
/// Supply keywords and relations; the view handles layout and rendering.
public struct GraphCanvasView: View {
    public let keywords: [String]
    public let relations: [KeywordRelation]

    @State private var nodes: [LayoutNode] = []
    @State private var canvasSize: CGSize = .zero
    @State private var needsLayout: Bool = true

    private let nodeRadius: CGFloat = 26
    private let iterationCount = 55

    public init(keywords: [String], relations: [KeywordRelation]) {
        self.keywords = keywords
        self.relations = relations
    }

    public var body: some View {
        Canvas { context, size in
            if needsLayout || nodes.isEmpty { runLayout(in: size) }

            // Draw edges
            for rel in relations {
                guard let src = nodes.first(where: { $0.keyword == rel.source }),
                      let tgt = nodes.first(where: { $0.keyword == rel.target }) else { continue }

                let path = Path { p in
                    p.move(to: CGPoint(x: src.x, y: src.y))
                    p.addLine(to: CGPoint(x: tgt.x, y: tgt.y))
                }
                let alpha = min(0.35, max(0.06, rel.weight * 0.22))
                context.stroke(path, with: .color(.secondary.opacity(alpha)), lineWidth: max(1, rel.weight * 2))
            }

            // Draw nodes
            for node in nodes {
                let center = CGPoint(x: node.x, y: node.y)
                let rect = CGRect(x: center.x - nodeRadius, y: center.y - nodeRadius,
                                  width: nodeRadius * 2, height: nodeRadius * 2)

                let color: Color = node.pinned ? .accentColor : .accentColor.opacity(0.65)
                context.fill(Circle().path(in: rect), with: .color(color))
                context.stroke(Circle().path(in: rect), with: .color(.white.opacity(0.25)), lineWidth: 1.2)

                // Label
                let text = Text(node.keyword).font(.system(size: 10, weight: .medium))
                let resolved = context.resolve(text)
                let ts = resolved.measure(in: .init(width: 80, height: 16))
                let lx = center.x - ts.width / 2
                let ly = center.y + nodeRadius + 4
                context.draw(resolved, at: CGPoint(x: lx + ts.width / 2, y: ly + ts.height / 2))
            }
        }
        .overlay {
            GeometryReader { geo in
                Color.clear
                    .onAppear { canvasSize = geo.size; needsLayout = true }
                    .onChange(of: geo.size) { _, s in canvasSize = s; needsLayout = true }
            }
        }
        .onChange(of: keywords.count) { _, _ in needsLayout = true }
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    let loc = value.location
                    if let idx = nodes.firstIndex(where: {
                        hypot($0.x - loc.x, $0.y - loc.y) < nodeRadius + 10
                    }) {
                        nodes[idx].x = loc.x
                        nodes[idx].y = loc.y
                        nodes[idx].pinned = true
                    }
                }
        )
        .onTapGesture(count: 2) {
            nodes.indices.forEach { nodes[$0].pinned = false }
            needsLayout = true
        }
    }

    // MARK: - Force layout

    private func runLayout(in size: CGSize) {
        let w = max(size.width, 280)
        let h = max(size.height, 200)
        guard !keywords.isEmpty else { return }
        let cx = w / 2
        let cy = h / 2
        let r = min(w, h) / 2.5

        // Initialize positions in a circle
        var newNodes: [LayoutNode] = []
        for (i, kw) in keywords.enumerated() {
            if let existing = nodes.first(where: { $0.keyword == kw && $0.pinned }) {
                newNodes.append(existing)
            } else {
                let angle = (2 * .pi * Double(i)) / Double(keywords.count) - .pi / 2
                newNodes.append(LayoutNode(
                    id: kw, keyword: kw,
                    x: cx + CGFloat(cos(angle)) * CGFloat(r),
                    y: cy + CGFloat(sin(angle)) * CGFloat(r)
                ))
            }
        }
        nodes = newNodes

        // Build adjacency
        var adj: [String: Set<String>] = [:]
        for rel in relations {
            adj[rel.source, default: []].insert(rel.target)
            adj[rel.target, default: []].insert(rel.source)
        }

        let margin: CGFloat = nodeRadius + 6
        let maxX = w - margin
        let maxY = h - margin
        let k: CGFloat = max(w, h) * 0.28
        let temp: CGFloat = max(w, h) * 0.018

        for iter in 0..<iterationCount {
            var disp = Array(repeating: CGPoint.zero, count: nodes.count)

            // Repulsion
            for i in 0..<nodes.count where !nodes[i].pinned {
                for j in 0..<nodes.count where i != j {
                    var dx = nodes[i].x - nodes[j].x
                    var dy = nodes[i].y - nodes[j].y
                    var dist = hypot(dx, dy)
                    if dist < 1 { dist = 1; dx = 1; dy = 0 }
                    let force = (k * k) / dist
                    disp[i].x += (dx / dist) * force
                    disp[i].y += (dy / dist) * force
                }
            }

            // Attraction
            for rel in relations {
                guard let si = nodes.firstIndex(where: { $0.keyword == rel.source }),
                      let ti = nodes.firstIndex(where: { $0.keyword == rel.target }),
                      !nodes[si].pinned || !nodes[ti].pinned else { continue }
                var dx = nodes[si].x - nodes[ti].x
                var dy = nodes[si].y - nodes[ti].y
                var dist = hypot(dx, dy)
                if dist < 1 { dist = 1; dx = 1; dy = 0 }
                let force = (dist * dist) / k * CGFloat(rel.weight)
                if !nodes[si].pinned { disp[si].x -= (dx / dist) * force; disp[si].y -= (dy / dist) * force }
                if !nodes[ti].pinned { disp[ti].x += (dx / dist) * force; disp[ti].y += (dy / dist) * force }
            }

            // Apply with cooling
            let cooling = max(0.08, 1.0 - Double(iter) / Double(iterationCount))
            for i in 0..<nodes.count where !nodes[i].pinned {
                let d = disp[i]; let dist = hypot(d.x, d.y)
                if dist > 0 {
                    let limited = min(dist, temp * CGFloat(cooling))
                    nodes[i].x += (d.x / dist) * limited
                    nodes[i].y += (d.y / dist) * limited
                }
                nodes[i].x = max(margin, min(maxX, nodes[i].x))
                nodes[i].y = max(margin, min(maxY, nodes[i].y))
            }
        }
        needsLayout = false
    }
}
