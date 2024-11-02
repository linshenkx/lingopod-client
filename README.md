# LingoPod 客户端 📱

> LingoPod的跨平台客户端应用 - 随时随地享受双语播客学习体验

## 🌟 项目简介

LingoPod客户端是[LingoPod服务端](https://github.com/linshenkx/lingopod)的配套客户端应用程序，支持Android、Web和Windows平台。通过这款应用，用户可以在多个平台上轻松访问和收听AI生成的双语播客内容，实现随时随地的语言学习。

[放置应用截图]

## ✨ 核心特性

- 🌐 跨平台支持 (Android/Web/Windows)
- 🎧 在线播放双语播客
- 💫 优雅的音频切换动画
- 📝 同步显示双语字幕
- 🔄 多种播放模式(顺序/循环/单曲/随机)
- 🌙 深色模式支持
- 🔍 播客内容搜索
- 📥 音频和字幕缓存
- 🎛️ 可配置服务器地址

## 🛠️ 技术栈

- **框架**: Flutter 3.5.4+
- **状态管理**: Provider 6.1.1
- **网络**: Dio 5.4.1
- **音频播放**: audioplayers 5.2.1
- **数据持久化**: shared_preferences 2.2.2
- **缓存管理**: flutter_cache_manager 3.3.1

## 🚀 开始使用

### 环境要求

- Flutter SDK 3.5.4 或更高版本
- Dart SDK 3.5.4 或更高版本
- Android Studio / VS Code
- Chrome (Web版)
- Windows 10+ (Windows版)

### 安装步骤

```bash
# 克隆项目
git clone https://github.com/linshenkx/lingopod-client.git

# 进入项目目录
cd lingopod-client

# 安装依赖
flutter pub get

# 运行项目
flutter run
```

## 📱 主要功能

### 播放器功能
- 支持中英文音频切换
- 字幕显示模式切换(中英/仅中/仅英)
- 播放速度调节(0.75x-2.0x)
- 进度条拖动和时间显示
- 迷你播放器支持

### 播放列表管理
- 搜索过滤功能
- 删除播客
- 多种播放模式切换

### 系统设置
- 服务器地址配置
- 深色/浅色主题切换
- 缓存管理
- 连接测试

## 🔌 服务端配置

默认连接到 `http://localhost:28811/api`，可在设置中修改服务器地址。确保服务端正确运行并可访问。

## 📁 项目结构

```
lib/
├── main.dart                 # 入口文件
├── config/                   # 配置文件
├── models/                   # 数据模型
├── screens/                  # 页面
│   ├── home_screen.dart     # 主页
│   ├── player_screen.dart   # 播放器
│   └── settings_screen.dart # 设置页
├── providers/               # 状态管理
├── services/               # 服务
└── widgets/               # 组件
```

## 🤝 参与贡献

欢迎通过以下方式贡献：
- 🐛 报告问题
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码改进

## 📄 开源协议

本项目采用 [MIT 许可证](LICENSE) 开源。

## 🔗 相关链接

- [LingoPod 服务端](https://github.com/linshenkx/lingopod)
- [问题反馈](https://github.com/linshenkx/lingopod-client/issues)
