import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/external_links.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => ExternalLinks.debugOpener = null);

  test('赞助入口是 https 且指向爱发电主页', () {
    final url = Uri.parse(ExternalLinks.donationUrl);
    expect(url.scheme, 'https');
    expect(url.host, 'afdian.com');
  });

  test('拒绝非 https 地址，不交给浏览器', () async {
    var called = false;
    ExternalLinks.debugOpener = (url) async {
      called = true;
      return true;
    };
    expect(await ExternalLinks.open(Uri.parse('http://example.com')), isFalse);
    expect(await ExternalLinks.open(Uri.parse('intent://example')), isFalse);
    expect(called, isFalse);
  });

  test('打开赞助主页时把该地址原样交给浏览器', () async {
    final opened = <Uri>[];
    ExternalLinks.debugOpener = (url) async {
      opened.add(url);
      return true;
    };
    expect(await ExternalLinks.openDonation(), isTrue);
    expect(opened.single.toString(), ExternalLinks.donationUrl);
  });

  test('浏览器返回失败时归一为 false', () async {
    ExternalLinks.debugOpener = (url) async => false;
    expect(await ExternalLinks.openDonation(), isFalse);
  });

  test('宿主没有插件实现时不向调用方抛异常', () async {
    // 不注入 opener：测试宿主没有 url_launcher 实现，真实路径会抛
    // MissingPluginException，应由 open 归一为 false。
    expect(await ExternalLinks.openDonation(), isFalse);
  });
}
