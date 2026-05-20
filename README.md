# Ledger / 记账

本项目是本地资产记账 App 的 Flutter 版本，使用 GetX 管理状态、路由、弹窗和多语言。

## 当前定位

- 中文名称：记账
- 英文名称：Ledger
- Android 包名：`com.ggbong.ledger`
- iOS Bundle Identifier：建议也使用 `com.ggbong.ledger`
- 本地保存资产、理财、借款和图片凭证
- 行情估值通过你自己的聚合 API 获取
- API 地址和 API Token 均在 App 设置页填写，不写死在代码里

## 运行

如果是新项目目录，建议先这样生成平台目录，这样 Android/iOS 的包名会直接是 `com.ggbong.ledger`：

```bash
flutter create --org com.ggbong --project-name ledger .
flutter pub get
flutter analyze
flutter run
```

如果你已经有旧项目平台目录，先把 `lib/`、`assets/`、`pubspec.yaml` 替换成这个包里的文件，然后参考下面的“已有项目修改包名”。

## 设置 API

打开 App 后进入设置页，填写：

```text
API 地址：你的行情聚合 API 域名，例如 https://api.example.com
API Token：你的 APP_API_TOKEN
默认估值货币：CNY / USD / HKD 等
主题：跟随系统 / 浅色 / 深色
语言：跟随系统 / 中文 / English
```

语言、主题、API 地址、Token、资产、借款都会本地持久化保存。

## 多语言

文案在 JSON 文件里：

```text
assets/i18n/zh.json
assets/i18n/en.json
```

页面里使用 GetX：

```dart
Text('assets'.tr)
Text('settings'.tr)
```

动态占位使用 GetX 的 `@param` 格式：

```json
{
  "estimateIn": "@currency 估值"
}
```

```dart
'estimateIn'.trParams({'currency': 'CNY'})
```

## 已有项目修改包名

Android 主要检查这些位置：

```text
android/app/build.gradle 或 android/app/build.gradle.kts
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/.../MainActivity.kt
android/app/src/main/res/values/strings.xml
android/app/src/main/res/values-zh/strings.xml
```

推荐直接执行：

```bash
flutter create --org com.ggbong --project-name ledger .
```

如果你不想重新生成平台目录，可以手动确认：

```gradle
namespace "com.ggbong.ledger"
applicationId "com.ggbong.ledger"
```

AndroidManifest 建议使用本地化 app 名称：

```xml
android:label="@string/app_name"
```

字符串资源：

```xml
<!-- android/app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Ledger</string>
</resources>
```

```xml
<!-- android/app/src/main/res/values-zh/strings.xml -->
<resources>
    <string name="app_name">记账</string>
</resources>
```

iOS 在 Xcode 里检查：

```text
Bundle Identifier: com.ggbong.ledger
Display Name: Ledger
```

## Google Play 上架前建议

- 使用 release 包测试，不要只测 debug 包
- 确认 Android target SDK 满足 Google Play 要求
- 确认没有调试日志和敏感 API Token 写死在代码里
- 用 Android App Bundle 上传：

```bash
flutter build appbundle --release
```

Google Play 从 2025 年 8 月 31 日起要求新应用和应用更新面向 Android 15 / API 35 或更高版本。Flutter 项目需要确认 Android Gradle 配置里的 `targetSdk`/`targetSdkVersion` 已满足这个要求。

## 图标

图标暂时未处理。后续可以使用 `flutter_launcher_icons` 生成 Android/iOS 图标。

## 辅助脚本

项目里提供了两个辅助脚本，用于已有 Android 平台目录的本地化名称配置：

```powershell
# Windows PowerShell
./scripts/configure_android_release.ps1
```

```bash
# macOS / Linux
./scripts/configure_android_release.sh
```

它们会做：

- 把 AndroidManifest 的 `android:label` 改为 `@string/app_name`
- 添加 `INTERNET` 权限
- 写入英文应用名 `Ledger`
- 写入中文应用名 `记账`

`platform_setup/` 目录里也放了 Android/iOS 的本地化名称参考文件。不要直接把 `platform_setup` 当作 Flutter 平台目录运行，只用于复制/参考。

## About / Sponsorship

Settings includes an About dialog with open-source notes, technology links, and copy buttons.

To configure sponsorship addresses, edit:

```text
lib/data/about_catalog.dart
```

If a donation address is empty, the app shows it as not configured and disables the copy button.
