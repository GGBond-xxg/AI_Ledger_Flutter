# 密码锁 / 生物识别配置说明

本版本新增 App 密码锁：

- 可关闭密码锁。
- 可使用手机设备生物识别：Android 指纹、iOS Face ID。
- 可使用 App 独立 6 位数字密码。
- 独立密码连续输错 8 次后，会清空本地数据：资产、借款、API 地址、API Token、密码锁设置都会删除。

## Flutter 依赖

`pubspec.yaml` 已新增：

```yaml
local_auth: ^2.3.0
crypto: ^3.0.6
```

执行：

```bash
flutter pub get
```

## Android 配置

### 1. AndroidManifest.xml

路径：

```text
android/app/src/main/AndroidManifest.xml
```

在 `<manifest>` 下面、`<application>` 上面添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

### 2. MainActivity

如果运行时报 Android FragmentActivity 相关错误，将 `MainActivity.kt` 改成：

```kotlin
package com.ggbong.ledger

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

路径通常是：

```text
android/app/src/main/kotlin/com/ggbong/ledger/MainActivity.kt
```

如果你的路径还是 `com/example/ledger_flutter`，说明包名目录还没整理，建议按 `com.ggbong.ledger` 重建或迁移。

## iOS 配置

路径：

```text
ios/Runner/Info.plist
```

在 `<dict>` 中添加：

```xml
<key>NSFaceIDUsageDescription</key>
<string>Used to unlock Ledger with Face ID.</string>
```

如果你做了中文本地化，在：

```text
ios/Runner/zh-Hans.lproj/InfoPlist.strings
```

添加：

```text
NSFaceIDUsageDescription = "用于通过 Face ID 解锁记账";
```

## 使用方式

打开 App：

```text
设置 → 密码锁
```

可选择：

- 使用手机生物识别
- 使用独立 6 位密码
- 关闭密码锁

独立密码只保存 salt + sha256 hash，不保存明文密码。
