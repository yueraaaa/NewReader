import Foundation

/// Validates URLs for network safety: protocol allowlist + private IP blocking.
///
/// Coverage:
/// - Scheme allowlist (http/https only)
/// - Private/reserved IPv4 ranges (RFC 1918 + loopback + link-local + CGN + multicast + reserved)
/// - IPv6 loopback, link-local fe80::/10, ULA fc00::/7, NAT64 64:ff9b::/96,
///   IPv4-mapped IPv6 (::ffff:a.b.c.d) and 6to4 (::a.b.c.d)
/// - Integer/hex-encoded IPv4 (2130706433, 0x7f000001)
/// - Hostnames `localhost` and `localhost.localdomain`
public enum URLValidator {

    /// Allowed URL schemes for fetching remote content.
    private static let allowedSchemes: Set<String> = ["https", "http"]

    /// Private / reserved IPv4 prefixes (CIDR notation).
    private static let privateRanges: [(UInt32, UInt32)] = [
        (0x0A000000, 0x0AFFFFFF),       // 10.0.0.0/8
        (0x7F000000, 0x7FFFFFFF),       // 127.0.0.0/8 (loopback)
        (0xA9FE0000, 0xA9FEFFFF),       // 169.254.0.0/16 (link-local)
        (0xAC100000, 0xAC1FFFFF),       // 172.16.0.0/12
        (0xC0A80000, 0xC0A8FFFF),       // 192.168.0.0/16
        (0x64400000, 0x647FFFFF),       // 100.64.0.0/10 (CGN)
        (0xE0000000, 0xEFFFFFFF),       // 224.0.0.0/4 (multicast)
        (0xF0000000, 0xFFFFFFFF),       // 240.0.0.0/4 (reserved)
    ]

    /// Validate that a URL string is safe to fetch from.
    /// - Returns: The validated `URL` if safe, or `nil` otherwise.
    public static func validate(_ urlString: String) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)

        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme),
              let host = url.host?.lowercased(),
              !host.isEmpty else {
            return nil
        }

        // Strip IPv6 brackets (e.g. "[::1]" -> "::1") so the rest of the
        // checks can treat hostnames uniformly.
        let bareHost: String
        if host.hasPrefix("[") && host.hasSuffix("]") {
            bareHost = String(host.dropFirst().dropLast())
        } else {
            bareHost = host
        }

        // Block integer/decimal-encoded IPv4 (e.g. http://2130706433/ = 127.0.0.1,
        // http://0x7f000001/) — some URL parsers accept these and resolve them
        // to loopback.
        if isIntegerEncodedIPv4(bareHost) { return nil }

        // Block raw IPv4 addresses in private ranges.
        if isPrivateIPv4(bareHost) { return nil }

        // Block IPv6 special-purpose ranges.
        if isPrivateIPv6(bareHost) { return nil }

        // Block common internal hostnames.
        if bareHost == "localhost" || bareHost == "localhost.localdomain" { return nil }

        return url
    }

    /// Check if the host string is a valid URL at all (used for OPML import
    /// where we only want to skip obviously bad entries, not full validation).
    public static func isPlausibleURL(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme),
              let host = url.host, !host.isEmpty else {
            return false
        }
        return true
    }

    // MARK: - Private

    private static func isPrivateIPv4(_ host: String) -> Bool {
        guard let ip = ipv4ToUInt32(host) else { return false }
        for (low, high) in privateRanges {
            if ip >= low && ip <= high { return true }
        }
        return false
    }

    private static func ipv4ToUInt32(_ host: String) -> UInt32? {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return nil }
        var ip: UInt32 = 0
        for (i, part) in parts.enumerated() {
            guard let octet = UInt32(part), octet <= 255 else { return nil }
            ip |= octet << (24 - i * 8)
        }
        return ip
    }

    /// Detect decimal / octal / hex encoded IPv4 that some URL parsers
    /// resolve to private addresses (e.g. `2130706433` == `127.0.0.1`,
    /// `0x7f000001` == `127.0.0.1`).
    private static func isIntegerEncodedIPv4(_ host: String) -> Bool {
        // Must be a single token of digits / hex chars only.
        let chars = CharacterSet(charactersIn: "0123456789abcdefABCDEFxX")
        if host.unicodeScalars.contains(where: { !chars.contains($0) }) { return false }
        if host.isEmpty { return false }

        // Reject forms like 127.1, 0x7f.0x0.0x0.0x1 by ensuring host is a
        // single number, not dotted.
        if host.contains(".") { return false }

        let value: UInt64?
        if host.lowercased().hasPrefix("0x") {
            value = UInt64(host.dropFirst(2), radix: 16)
        } else {
            value = UInt64(host, radix: 10)
        }
        guard let v = value, v <= 0xFFFFFFFF else { return true }
        // Treat as the IPv4 address it would resolve to and re-check the
        // private-range table.
        let a = UInt32((v >> 24) & 0xFF)
        let b = UInt32((v >> 16) & 0xFF)
        let c = UInt32((v >> 8) & 0xFF)
        let d = UInt32(v & 0xFF)
        return isPrivateIPv4("\(a).\(b).\(c).\(d)")
    }

    /// Block IPv6 special-purpose ranges that should never be fetched
    /// from a user-supplied URL (SSRF defense).
    private static func isPrivateIPv6(_ host: String) -> Bool {
        let lower = host.lowercased()

        // Strip the zone ID if present (e.g. fe80::1%eth0)
        let bare = lower.split(separator: "%").first.map(String.init) ?? lower

        // Loopback
        if bare == "::1" || bare == "::" { return true }

        // Link-local fe80::/10
        if bare.hasPrefix("fe8") || bare.hasPrefix("fe9") ||
           bare.hasPrefix("fea") || bare.hasPrefix("feb") { return true }

        // Unique local addresses fc00::/7 (covers fc00::/8 and fd00::/8)
        if bare.hasPrefix("fc") || bare.hasPrefix("fd") { return true }

        // NAT64 well-known prefix 64:ff9b::/96
        if bare.hasPrefix("64:ff9b:") { return true }

        // Discard prefix 100::/64
        if bare.hasPrefix("100:") && bare.count >= 4 { return true }

        // IPv4-mapped IPv6 (::ffff:a.b.c.d). Catches ::ffff:127.0.0.1 etc.
        if bare.hasPrefix("::ffff:") {
            let v4 = String(bare.dropFirst("::ffff:".count))
            return isPrivateIPv4(v4)
        }

        // 6to4 / IPv4-compatible (::a.b.c.d) — deprecated but some parsers
        // still accept it; treat conservatively.
        if bare.hasPrefix("::") && bare.contains(".") {
            let v4 = String(bare.dropFirst(2))
            return isPrivateIPv4(v4)
        }

        return false
    }
}
