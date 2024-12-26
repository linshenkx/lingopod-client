## 配置apk签名
```shell
keytool -genkey -v -keystore ~/upload-keystore.jks -alias upload -storepass 123456 -keypass 123456 -dname "CN=Test" -validity 36500
```

## Flutter 打包 APK 文件

要生成 APK 文件，请按照以下步骤操作：

1. 确保你已经安装了 Flutter SDK 并且设置了 Android 开发环境。
2. 在项目的根目录中运行以下命令以确保所有依赖项都是最新的：

   ```bash
   flutter pub get
   ```

3. 使用以下命令构建 APK：

   ```bash
   flutter build apk --dart-define=DEFAULT_BASE_URL=https://server.lingopod.top
   ```

4. 构建完成后，APK 文件将位于 `build/app/outputs/flutter-apk/` 目录中。

5. 你可以通过以下命令安装 APK 到连接的 Android 设备：

   ```bash
   flutter install
   ```

## 构建 Web 版本
```shell
flutter build web --dart-define=DEFAULT_BASE_URL=https://server.lingopod.top

```

## 发布到vercel
```shell
npm install -g vercel
vercel login
flutter build web --dart-define=DEFAULT_BASE_URL=https://server.lingopod.top
cd build/web
vercel

```

## 发布新版本

要发布新版本，请按照以下步骤操作：

1. **提交代码**

   确保所有更改都已提交到代码库：

   ```bash
   git add .
   git commit -m "描述你的更改"
   ```

2. **创建新标签**

   使用以下命令创建一个新的标签（tag）：

   ```bash
   git tag vX.Y.Z
   ```

   请将 `vX.Y.Z` 替换为你的版本号，例如 `v1.0.0`。

3. **推送代码和标签**

   将代码和新标签推送到远程仓库：

   ```bash
   git push origin main
   git push origin vX.Y.Z
   ```

   请确保将 `main` 替换为你的主分支名称。

4. **GitHub Release**

   推送标签后，GitHub Actions 将自动触发构建和发布流程。

   - **发布正式版本**
     按照上述步骤，使用格式 `vX.Y.Z` 创建标签，如 `v1.0.0`

   - **发布 Beta 版本**
     1. 创建 beta 版本标签，使用格式 `vX.Y.Z-beta.N`：
     ```bash
     git tag v1.0.0-beta.1
     ```
     2. 推送 beta 标签：
     ```bash
     git push origin v1.0.0-beta.1
     ```
     3. 在 GitHub Releases 页面，该 beta 版本会被自动标记为 "Pre-release"

5. **撤销发布**

   如果需要撤销发布版本，请按照以下步骤操作：

   1. **删除远程标签**

      使用以下命令删除远程仓库中的标签：

      ```bash
      git push --delete origin vX.Y.Z
      ```

   2. **删除本地标签**

      使用以下命令删除本地标签：

      ```bash
      git tag -d vX.Y.Z
      ```

   3. **删除 GitHub Release**

      在 GitHub Releases 页面中，手动删除对应的 Release。

6. **部署说明**

   - **Web 版本部署**
     1. 解压 `lingopod-web.zip` 到 Web 服务器目录。
     2. 配置服务器地址。

   - **桌面端**
     1. 解压 Windows 压缩包。
     2. 运行可执行文件。
     3. 在设置中配置服务器地址。
