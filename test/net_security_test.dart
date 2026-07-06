import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/net_security.dart';

void main() {
  group('isCleartextCredentialRisk', () {
    test('https 一律不告警', () {
      expect(isCleartextCredentialRisk('https://api.openai.com/v1'), isFalse);
      expect(isCleartextCredentialRisk('https://myserver.com'), isFalse);
    });

    test('http 公网域名 / 公网 IP 告警', () {
      expect(isCleartextCredentialRisk('http://api.example.com/v1'), isTrue);
      expect(isCleartextCredentialRisk('http://8.8.8.8:11434'), isTrue);
      expect(isCleartextCredentialRisk('http://203.0.113.5'), isTrue);
    });

    test('http 本机 / 内网不告警', () {
      expect(isCleartextCredentialRisk('http://localhost:11434'), isFalse);
      expect(isCleartextCredentialRisk('http://127.0.0.1:1234'), isFalse);
      expect(isCleartextCredentialRisk('http://192.168.1.100:11434'), isFalse);
      expect(isCleartextCredentialRisk('http://10.0.0.5'), isFalse);
      expect(isCleartextCredentialRisk('http://172.16.3.4:8080'), isFalse);
      expect(isCleartextCredentialRisk('http://172.20.0.1'), isFalse);
      expect(isCleartextCredentialRisk('http://nas.local:5000'), isFalse);
      expect(isCleartextCredentialRisk('http://[::1]:8080'), isFalse);
    });

    test('172.32 属公网（超出 172.16-31）', () {
      expect(isCleartextCredentialRisk('http://172.32.0.1'), isTrue);
    });

    test('空 / 非法输入不告警', () {
      expect(isCleartextCredentialRisk(''), isFalse);
      expect(isCleartextCredentialRisk('not a url'), isFalse);
    });
  });
}
