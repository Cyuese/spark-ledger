# jdenticon_dart（本地 vendor）

[`jdenticon_dart`](https://pub.dev/packages/jdenticon_dart) 2.0.0，MIT，Copyright (c) 2019
Vergill Lemmert，见同目录 `LICENSE`。它把输入字符串哈希成一张 SVG identicon
（`Jdenticon.toSvg(input)` → 原始 SVG 字符串，用 `flutter_svg` 渲染）。

**为什么 vendor 而不是直接依赖**：上游 `pubspec.yaml` 的 SDK 上限停在 `<3.0.0`
（最后一次发布于 2021-03），本项目跑 Dart 3，`pub get` 无法解析该约束；而上游代码
本身在 Dart 3 下可正常编译。

**与上游的差异只有两处**（都在 `pubspec.yaml`）：`environment.sdk` 放宽到
`>=3.0.0 <4.0.0`、`crypto` 下限提到 `^3.0.6`（与本仓库其余部分一致）。`lib/` 与
`LICENSE` 与上游发布包逐字节一致。

**引入方式**：根 `pubspec.yaml` 用 `path:` 依赖它。等上游发布支持 Dart 3 的版本后，
删掉本目录、把依赖换成版本约束即可；届时 `lib/` 的 diff 就是同步凭据。

**维护约定**：不要在本目录里做业务改动。需要定制（颜色、留白、尺寸）时用
`Jdenticon.toSvg` 的参数在调用点表达，见 `lib/app/credits_avatar.dart`。

## 许可

MIT。分发本应用时保留本目录的 `LICENSE` 即满足署名要求。
