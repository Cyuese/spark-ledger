/// 网络安全判定纯函数。
///
/// Android 无法在 `network_security_config` 里按内网 IP 段放行明文，因此保留全局
/// 允许明文（局域网自建 http AI / WebDAV 是有意支持的场景），改在「配置端点」时
/// 提醒：若用 http 把凭证发往**公网**主机，API Key / 账号密码会明文传输、可被
/// 同网络或链路上的第三方窃取。localhost / 回环 / RFC1918 私有网段视为相对可信、不告警。
library;

/// URL 是否会以明文（http）把凭证发往非本机 / 非内网的公网主机。
bool isCleartextCredentialRisk(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  if (uri.scheme.toLowerCase() != 'http') return false; // https 及其他不告警
  final host = uri.host;
  if (host.isEmpty) return false;
  return !isLocalOrPrivateHost(host);
}

/// 主机是否为本机 / 内网（回环、RFC1918 私有段、link-local、localhost/.local）。
bool isLocalOrPrivateHost(String host) {
  final h = host.toLowerCase();
  if (h == 'localhost' || h.endsWith('.local')) return true;
  if (h == '::1') return true; // IPv6 回环

  final parts = h.split('.');
  if (parts.length == 4) {
    final octets = parts.map(int.tryParse).toList();
    if (octets.every((o) => o != null && o >= 0 && o <= 255)) {
      final a = octets[0]!;
      final b = octets[1]!;
      if (a == 127) return true; // 回环 127/8
      if (a == 10) return true; // 10/8
      if (a == 172 && b >= 16 && b <= 31) return true; // 172.16/12
      if (a == 192 && b == 168) return true; // 192.168/16
      if (a == 169 && b == 254) return true; // link-local 169.254/16
      return false; // 其他 IPv4 = 公网
    }
  }
  return false; // 普通域名 = 公网
}
