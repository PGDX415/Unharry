# CLAUDE.md

本文件为 Claude Code 在此仓库中工作时提供指导。

## 项目概述

- **产品名称**：闲眠（英文：Unhurry）
  - 命名理念："闲"取自"闲适、放下匆忙"，"眠"对应睡眠，整体传达
    "不慌不忙、允许自己慢下来入睡"的态度
- **App 定位**：一款 iOS 助眠 App，帮助用户通过白噪音/自然音混音、睡前故事、
  呼吸引导练习等功能改善睡眠质量。
- **平台**：iOS 18.0+
- **语言/框架**：Swift 5.0 + SwiftUI
- **架构**：MVVM，所有 ViewModel 使用 `@Observable`（iOS 17+ 宏）
- **项目版本**：v1.0（build 1）

## 构建系统

- **工程生成**：[xcodegen](https://github.com/yonaskolov/XcodeGen)——工程文件由 [project.yml](project.yml) 生成，**不要手动修改 `.xcodeproj`**
- **生成命令**：
  ```bash
  cd /Users/gongdexin/Projects/active/Unhurry
  xcodegen generate
  ```
- **三个 target**：`Unhurry`（主 App）、`UnhurryWidget`（Widget 扩展）、`UnhurryTests`（单元测试）
- **Bundle ID**：`com.gongdexin.paul.Unhurry`
- **开发团队**：`SJ8DC28NRH`
- **部署目标**：iOS 18.0
- **xcodeVersion**：16.0

## 技术栈

| 领域 | 技术 |
|------|------|
| UI | SwiftUI（纯声明式，无 UIKit wrapper） |
| 音频播放/混音 | AVFoundation（AVAudioEngine + AVAudioPlayerNode） |
| 后台播放 | Background Modes: audio |
| 触觉反馈 | CoreHaptics（CHHapticEngine） |
| 健康数据 | HealthKit（mindfulSession 正念分钟） |
| 通知推送 | UserNotifications（UNCalendarNotificationTrigger 每日就寝提醒） |
| Widget | WidgetKit（systemSmall/medium + accessoryCircular/Rectangular/Inline） |
| 本地持久化 | UserDefaults（通过 App Group `group.com.gongdexin.paul.Unhurry` 共享） |
| 数据架构 | `@Observable` + `@AppStorage`，无 Core Data / SwiftData |
| 依赖管理 | 无第三方 SPM 依赖，纯 Apple 原生框架 |
| 文本转语音 | AVSpeechSynthesizer（TTS 朗读睡前故事） |
| 代码签名 | Automatic（Xcode 自动管理） |

## 项目结构

```
Unhurry/
├── project.yml                        # xcodegen 工程定义文件
├── Unhurry.xcodeproj/                 # 由 xcodegen 生成，勿手动修改
├── Unhurry/
│   ├── App/
│   │   ├── AppDelegate.swift          # UIApplicationDelegate + UNUserNotificationCenterDelegate
│   │   └── UnhurryApp.swift           # @main App 入口，组装 ViewModel 依赖
│   ├── Models/
│   │   ├── SoundTrack.swift           # 音效元数据（id, name, category, fileName, volume）
│   │   ├── SoundCategory.swift        # 音效分类枚举（rain, water, nature, whiteNoise, meditation, music）
│   │   ├── MixPreset.swift            # 混音预设（Codable，支持 Widget 共享）
│   │   └── StoryItem.swift            # 睡前故事/冥想引导条目（含全文内容）
│   ├── ViewModels/
│   │   ├── SoundPlayerViewModel.swift # 音效混音播放核心逻辑 + 收藏
│   │   ├── TimerViewModel.swift       # 睡眠计时器状态
│   │   ├── StoryPlayerViewModel.swift # 故事/冥想播放（TTS + 预录音频）
│   │   └── BreathViewModel.swift      # 呼吸引导练习（动画 + CoreHaptics）
│   ├── Views/
│   │   ├── ContentView.swift          # 主页面（品牌头 + 呼吸入口 + 故事入口 + 计时器 + 音效库 + 混音面板）
│   │   ├── Sounds/
│   │   │   ├── SoundLibraryView.swift  # 音效库（分类浏览 + 收藏 + 播放/停止）
│   │   │   └── ActiveMixerPanel.swift  # 当前活跃混音面板（音量调节 + 保存预设）
│   │   ├── Stories/
│   │   │   ├── StoryLibraryView.swift  # 故事列表（冥想引导 / 睡前故事）
│   │   │   └── StoryPlayerView.swift   # 故事播放器（文字稿 + 进度 + 高亮）
│   │   ├── Breath/
│   │   │   └── BreathView.swift        # 呼吸练习页（动画圆 + 震动同步）
│   │   ├── Timer/
│   │   │   └── TimerControlView.swift  # 睡眠计时器控制
│   │   ├── Settings/
│   │   │   └── SettingsView.swift      # 设置页（统计/提醒/音量/缓冲/主题/健康）
│   │   └── Stats/
│   │       └── StatsView.swift         # 使用统计（周统计 + 最爱音效排行）
│   ├── Services/
│   │   ├── AudioService.swift          # 音频引擎核心（混音/循环/淡入淡出/后台）
│   │   ├── AudioServiceProtocol.swift  # AudioService 协议（便于测试 mock）
│   │   ├── AudioSessionManager.swift   # AVAudioSession 生命周期管理
│   │   ├── NoiseGenerator.swift        # 白噪音/粉噪音/棕噪音算法生成
│   │   ├── SoundLibrary.swift          # 内置音效目录 + 预加载
│   │   ├── SleepTimer.swift            # 定时渐弱停止播放
│   │   ├── NowPlayingController.swift  # 锁屏/控制中心 Now Playing 信息
│   │   ├── TTSService.swift            # AVSpeechSynthesizer 文本转语音
│   │   ├── UsageTracker.swift          # 使用统计追踪（@Observable 单例）
│   │   ├── HealthService.swift         # HealthKit 正念分钟同步
│   │   └── ReminderService.swift       # 就寝提醒通知调度
│   ├── Theme/
│   │   └── Theme.swift                 # 主题系统（强调色/背景色/所有设置项）
│   ├── Extensions/
│   │   └── AVAudioPCMBuffer+TestTone.swift
│   ├── Resources/
│   │   └── Audio/                      # AI 生成的 mp3 音频文件（26 个）
│   ├── Base.lproj/
│   │   └── LaunchScreen.storyboard     # 启动页（🌙 闲眠 宁静入眠）
│   ├── Info.plist
│   └── Unhurry.entitlements            # App Group + HealthKit
├── UnhurryWidget/
│   ├── UnhurryWidget.swift             # Widget 定义 + 所有尺寸视图
│   ├── UnhurryWidgetBundle.swift       # WidgetBundle 入口
│   ├── Provider.swift                  # TimelineProvider（从 App Group 读 MixPreset）
│   ├── Info.plist
│   └── UnhurryWidget.entitlements      # App Group 权限
├── UnhurryTests/
│   ├── Services/
│   │   ├── AudioServiceTests.swift
│   │   ├── NoiseGeneratorTests.swift
│   │   └── SleepTimerTests.swift
│   └── TestHelpers/
│       └── AudioTestHelpers.swift
└── Scripts/
    └── generate_icon.swift             # App 图标生成（SF Symbol → 1024px PNG）
```

## 核心功能模块

### 1. 音频播放引擎（AudioService）
- AVAudioEngine 多音轨混音，每个音效一个 AVAudioPlayerNode
- 支持无缝循环、独立音量控制、淡入淡出
- NoiseGenerator：纯代码生成白/粉/棕噪音（AVAudioPCMBuffer），零版权
- NowPlayingController：锁屏/控制中心 Now Playing 信息
- 后台持续播放（`UIBackgroundModes: audio`）

### 2. 音效库（SoundLibrary）
- **20 个音效**：
  - 代码生成（3）：白噪音、粉噪音、棕噪音（`.caf`，运行时生成 buffer）
  - AI 自然音（12）：轻雨、海浪、篝火、微风、溪流、远雷、夜林、风扇、屋檐听雨、雨打车窗、瀑布、夏夜虫鸣、风吹竹林（`.mp3`，ElevenLabs）
  - AI 音乐（5）：八音盒、颂钵疗愈、大提琴夜曲、水中钢琴、深空漫游（`.mp3`）
  - 其他（2）：古琴、心跳
- 分类：rain / water / nature / whiteNoise / music / meditation
- **收藏功能**：心形按钮切换，持久化到 UserDefaults `com.unhurry.favorites`

### 3. 混音预设（MixPreset）
- 用户可混合任意音效、保存为预设（名称 + trackIds + volumes）
- 通过 App Group UserDefaults 持久化，Widget 和主 App 共享
- Widget 点击预设 → `unhurry://play?id=xxx` URL scheme → App 自动加载

### 4. 睡眠计时器（SleepTimer）
- 预设：15 分钟 / 30 分钟 / 1 小时，倒计时结束渐弱停止

### 5. 睡前故事 / 冥想引导
- **6 个内容**：呼吸放松、身体扫描、月亮的故事、星星的旅程、云上的家、感恩入睡
- 两个分类：冥想引导 / 睡前故事
- 双播放模式：预录音频 `.mp3` + TTS 降级（AVSpeechSynthesizer）
- 文字稿同步高亮、播放/暂停、进度跳转

### 6. 呼吸引导练习（BreathView）
- 吸气 4 秒 / 呼气 6 秒，圆形缩放动画（1.0 ↔ 1.3）
- CoreHaptics 同步震动：吸气渐强、呼气渐弱（CHHapticEngine + CHHapticParameterCurve）
- 预设时长：3 / 5 / 10 分钟
- 完成 ≥60 秒时自动同步到 Apple Health 正念分钟

### 7. Widget（UnhurryWidget）
- 支持 5 种尺寸：systemSmall、systemMedium、accessoryCircular、accessoryRectangular、accessoryInline
- 从 App Group 读取预设，点击通过 URL scheme 启动 App
- 每小时自动刷新

### 8. 设置页（SettingsView）
- **使用统计** → 跳转 StatsView（本周次数、时长、Top 5 音效）
- **就寝提醒**：开关 + 时间选择 + 预设绑定（UNCalendarNotificationTrigger）
- **默认音量**：Slider 0-100%
- **缓冲时长**：即时 / 3秒 / 5秒
- **强调色**：暖金 / 月光银 / 薰衣草紫
- **背景模式**：暮色紫 / OLED 纯黑
- **健康同步**：开关控制 HealthKit 正念分钟写入

### 9. Apple Health 集成（HealthService）
- 类型：`HKCategoryTypeIdentifier.mindfulSession`
- 触发条件：播放 ≥60 秒 + `Theme.healthSyncEnabled == true`
- 权限描述在 `Info.plist` 中声明（NSHealthShareUsageDescription / NSHealthUpdateUsageDescription）

### 10. 就寝提醒（ReminderService）
- 每日 `UNCalendarNotificationTrigger`
- 通知携带 `presetId`，点击后 AppDelegate 回调加载预设
- 前台显示 banner + sound

## 主题系统（Theme.swift）

所有设置通过 `UserDefaults.standard` 持久化，`@AppStorage` 在 SwiftUI 中响应变化：

| 属性 | 默认值 | 说明 |
|------|--------|------|
| `accentThemeRaw` | `"gold"` | gold / silver / lavender |
| `useBlackBackground` | `false` | OLED 纯黑背景 |
| `defaultVolume` | `0.5` | 新音效初始音量 |
| `bufferDuration` | `3.0` | 播放前延迟（0/3/5） |
| `healthSyncEnabled` | `true` | 健康同步开关 |
| `reminderEnabled` | `false` | 就寝提醒开关 |
| `reminderHour` / `reminderMinute` | 22:00 | 提醒时间 |

**强调色**：
- 暖金 `#F0E6D2` — 默认
- 月光银 `#D1D1D9`
- 薰衣草紫 `#BFA6E6`

**背景色**：暮色紫 `#372F52` / OLED 纯黑 `#0D0D0D`

**主题反应性**：`ContentView` 使用 `.id(themeVersion)` + `onChange(of:)` 在主题切换时强制重建视图树。

## 音频文件

全部位于 `Unhurry/Resources/Audio/`（xcodegen folder reference，平铺到 Bundle 根）：

| 文件 | 名称 | 分类 | 来源 |
|------|------|------|------|
| `ai_rain_light.mp3` | 轻雨 | rain | ElevenLabs |
| `ai_ocean_calm.mp3` | 海浪 | water | ElevenLabs |
| `ai_fire_camp.mp3` | 篝火 | nature | ElevenLabs |
| `ai_wind_breeze.mp3` | 微风 | nature | AI |
| `ai_stream_flow.mp3` | 溪流 | water | AI |
| `ai_thunder_slow.mp3` | 远雷 | rain | AI |
| `ai_forest_night.mp3` | 夜林 | nature | AI |
| `ai_fan_hum.mp3` | 风扇 | whiteNoise | AI |
| `ai_roof_rain.mp3` | 屋檐听雨 | rain | AI |
| `ai_car_rain.mp3` | 雨打车窗 | rain | AI |
| `ai_waterfall.mp3` | 瀑布 | water | AI |
| `ai_summer_bugs.mp3` | 夏夜虫鸣 | nature | AI |
| `ai_bamboo_wind.mp3` | 风吹竹林 | nature | AI |
| `ai_guqin.mp3` | 古琴 | meditation | AI |
| `ai_heartbeat.mp3` | 心跳 | whiteNoise | AI |
| `ai_music_box.mp3` | 八音盒 | music | AI |
| `ai_singing_bowl.mp3` | 颂钵疗愈 | music | AI |
| `ai_cello_nocturne.mp3` | 大提琴夜曲 | music | AI |
| `ai_underwater_piano.mp3` | 水中钢琴 | music | AI |
| `ai_deep_space.mp3` | 深空漫游 | music | AI |
| `meditation_breath.mp3` | 呼吸放松 | 故事 | TTS |
| `meditation_body_scan.mp3` | 身体扫描 | 故事 | TTS |
| `meditation_gratitude.mp3` | 感恩入睡 | 故事 | TTS |
| `story_moon.mp3` | 月亮的故事 | 故事 | TTS |
| `story_star.mp3` | 星星的旅程 | 故事 | TTS |
| `story_cloud.mp3` | 云上的家 | 故事 | TTS |

代码生成的噪声（白色/粉色/棕色，运行时 AVAudioPCMBuffer，不依赖外部文件）。

## App 图标与启动页

- **图标**：`moon.stars.fill` SF Symbol，金色 `#E8C547` 在暮色紫 `#372F52` 上，1024×1024px，由 [Scripts/generate_icon.swift](Scripts/generate_icon.swift) 生成
- **启动页**：[Unhurry/Base.lproj/LaunchScreen.storyboard](Unhurry/Base.lproj/LaunchScreen.storyboard)，UIStackView 居中显示 🌙 + "闲眠"（44pt light 暖金）+ "宁静入眠"（20pt thin 55% 透明），背景 `#372F52`

## URL Scheme

- `unhurry://play?id=<uuid>`：Widget / 通知点击时启动 App 并加载指定 MixPreset

## AppDelegate（AppDelegate.swift）

- 遵循 `UIApplicationDelegate` + `UNUserNotificationCenterDelegate`
- `didFinishLaunchingWithOptions`：设置通知 delegate + 请求权限
- `didReceive response`：提取 `presetId` → 通过 `onNotificationPreset` 闭包回调给 UnhurryApp
- `willPresent`：前台显示 banner + sound

## 编码约定

- **ViewModel**：`@Observable` + `@MainActor`，逻辑在 ViewModel，View 仅布局
- **异步**：统一 `async/await`
- **颜色**：不硬编码 `Color` 字面量或 `.secondary`/`.tertiary`，统一用 `Theme.accentColor.opacity(x)`
- **背景**：每页最外层 `ZStack` + `bgColor.ignoresSafeArea()`，`@AppStorage("useBlackBackground")` 响应切换
- **音频**：全部通过 AudioService 管理，提供 AudioServiceProtocol 便于测试 mock
- **工程**：只改 `project.yml`，`xcodegen generate` 生成 `.xcodeproj`

## 常用命令

```bash
# 生成工程（修改 project.yml 后必须执行）
xcodegen generate

# 构建
xcodebuild -scheme Unhurry -destination 'platform=iOS Simulator,name=iPhone 16' build

# 测试
xcodebuild -scheme Unhurry -destination 'platform=iOS Simulator,name=iPhone 16' test

# 生成 App 图标
swift Scripts/generate_icon.swift
```

## 测试

- 已有测试：AudioServiceTests、NoiseGeneratorTests、SleepTimerTests
- 新增 Service 层逻辑需补单元测试
- 音频功能优先真机验证（模拟器音频行为可能不一致）
- UI 变更需在暮色紫和 OLED 纯黑两种背景下分别检查

## 待定 / 未来迭代

- 商业模式（订阅 / 内购 / 买断）
- 账号系统与云同步
- 智能闹钟（HealthKit/CoreMotion 浅睡唤醒）
- 音频云端加载 + 本地缓存
- 正式商标查询与 App Store Connect 名称验证
- 深色/浅色双套 App 图标
- 多语言本地化
