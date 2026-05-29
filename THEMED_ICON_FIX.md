# Android 主题取色图标修复

本项目已补充 Android 13+ Themed Icons 需要的 monochrome 图层。

改动：

- `assets/icon/app_icon_monochrome.png`：新增单色透明图标。
- `pubspec.yaml`：新增 `adaptive_icon_monochrome` 配置，并升级 `flutter_launcher_icons` 到 `^0.14.4`。
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`：新增 `<monochrome>` 图层。
- `android/app/src/main/res/drawable-*/ic_launcher_monochrome.png`：预生成 Android 各密度单色图标，避免忘记运行生成命令时不生效。

重新生成图标命令：

```bash
flutter pub get
dart run flutter_launcher_icons
flutter clean
flutter build apk --release
```

测试时建议先卸载手机上的旧 App，再安装新 APK。部分桌面会缓存旧图标，需要重启桌面或手机。

注意：Flutter 的 `dynamic_color` 只影响 App 内部 UI 取色，不影响桌面启动图标。桌面图标取色依赖 Android adaptive icon 的 `monochrome` 图层，以及系统/桌面是否开启“主题图标”。
