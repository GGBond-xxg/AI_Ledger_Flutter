# Release 包无法联网 / API 测试 Failed host lookup 的修复

如果 debug 能联网，release APK/AAB 测试 API 报：

```text
SocketException with SocketFailed host lookup
No address associated with hostname
```

最常见原因是 `android/app/src/main/AndroidManifest.xml` 没有把 INTERNET 权限写到 **main** manifest。

请在 `<manifest ...>` 下面、`<application ...>` 上面加入：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

示例：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:label="@string/app_name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

改完后执行：

```powershell
flutter clean
flutter pub get
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols/android
```

然后卸载旧 App 再安装新包：

```powershell
adb uninstall com.ggbong.ledger
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## iOS

iOS 使用 `https://YourDomainName` 这种 HTTPS 地址不需要额外网络权限。相册/相机权限保留在 `Info.plist` 即可。

如果 iOS 也请求失败，优先检查：

1. API 地址是否是 `https://YourDomainName`，不要填错域名。
2. 手机是否能用 Safari 打开 `https://YourDomainName/api/health?token=你的token`。
3. 如果以后改成 HTTP 域名，才需要配置 ATS。

## 本版 UI 修复

- 设置页保存/测试 API 的底部提示改成自定义 toast，浅色/深色模式都能看清。
- 修复系统 snackbar 在浅色背景下文字发白的问题。
