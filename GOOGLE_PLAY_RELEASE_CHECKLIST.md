# Google Play Release Checklist

## 基础信息

- App 中文名：记账
- App 英文名：Ledger
- Android package name：com.ggbong.ledger
- 推荐上传格式：AAB

## 构建命令

```bash
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```

生成文件一般在：

```text
build/app/outputs/bundle/release/app-release.aab
```

## Android 版本要求

Google Play 当前要求新应用和应用更新目标 API 级别达到 Android 15 / API 35 或更高。检查：

```text
android/app/build.gradle
android/app/build.gradle.kts
```

确认：

```text
targetSdkVersion 35+
compileSdkVersion 35+
```

或者 Kotlin DSL：

```text
targetSdk = 35+
compileSdk = 35+
```

## 隐私和权限

当前 App 的设计原则：

- 资产和借款记录保存在本机
- 图片凭证压缩后保存在本地数据和 JSON 备份里
- 行情接口只用于估值，不在 App 代码里硬编码 API Token
- 不主动采集通讯录、定位、短信等敏感权限

如果开启拍照/相册凭证，Android/iOS 需要说明用途。
