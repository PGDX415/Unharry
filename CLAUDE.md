# CLAUDE.md

本文件为 Claude Code 在此仓库中工作时提供指导。

## 项目概述

- **产品名称**：闲眠（英文：Unhurry）
  - 命名理念："闲"取自"闲适、放下匆忙"，"眠"对应睡眠，整体传达
    "不慌不忙、允许自己慢下来入睡"的态度，区别于市面上直白的
    "睡眠/助眠"类命名
  - 命名冲突排查：已通过网络搜索初步确认 App Store 上无同名助眠类
    产品（中文"闲眠"、英文"Unhurry"均未发现直接冲突）。**注意**：
    网络搜索不等同于权威商标查询，正式提审前仍需在 App Store
    Connect 中实测名称可用性，并视预算做正式商标查询

一款 iOS 助眠 App，帮助用户通过白噪音/自然音、睡前故事、冥想引导、
睡眠追踪等功能改善睡眠质量。

- **平台**：iOS 17+（可根据实际最低支持版本调整）
- **语言/框架**：Swift + SwiftUI
- **架构**：MVVM
- **当前阶段**：项目初始化中，尚无代码

## 技术栈

- UI：SwiftUI
- 音频播放/混音：AVFoundation
- 睡眠数据读写：HealthKit
- 后台播放：Background Modes（audio）
- 本地持久化：SwiftData（或 Core Data，视需求确定）
- 小组件：WidgetKit（锁屏快速启动，后续迭代）
- 依赖管理：Swift Package Manager（优先，尽量不引入 CocoaPods）

## 项目结构（建议）

```
SleepApp/
├── SleepApp.xcodeproj
├── SleepApp/
│   ├── App/                 # App 入口、启动配置
│   ├── Models/               # 数据模型
│   ├── ViewModels/            # 各功能的 ViewModel
│   ├── Views/                 # SwiftUI 视图，按功能模块分子目录
│   │   ├── Sounds/            # 白噪音/混音
│   │   ├── Stories/            # 睡前故事/冥想
│   │   ├── Timer/              # 睡眠计时器
│   │   ├── SleepTracking/       # 睡眠追踪
│   │   └── Settings/
│   ├── Services/               # AudioService, HealthKitService 等
│   ├── Resources/               # 音频文件、图片、本地化文件
│   └── Extensions/
├── SleepAppTests/
└── SleepAppUITests/
```

> 注：此结构会随项目推进调整，如有变化请同步更新本文件。

## 品牌视觉与 App 图标

- **图标设计方向**：极简新月（暮色紫方案）
  - 视觉构成：两个圆形做布尔运算式相减，形成不对称月牙造型；
    背景为纯色暮色紫（参考色值 `#372f52`），月牙为暖白色
    （参考色值 `#f0e6d2`）
  - 设计理念：呼应"闲眠"意境——暮色是"入夜前"的过渡时刻，
    新月对应睡眠场景，整体克制、留白多，避免复杂插画堆砌
  - 风格要求：扁平设计，不使用渐变/阴影/发光效果；单一视觉主体，
    保证在 iOS 桌面小尺寸图标下依然清晰可辨
  - 品牌延展：暮色紫（`#372f52`）作为 App 主题色基础，后续启动页、
    主色调 UI 元素应与图标视觉统一
- **技术规范**（正式出图时遵循）：
  - 主图：1024×1024px，无透明通道，系统自动裁切圆角，设计时注意
    关键元素不要贴边（预留安全边距）
  - 后续迭代可考虑补充深色/浅色两套图标（iOS 17+ 支持系统外观
    自动切换），非 MVP 必需
- **当前状态**：仅完成概念方向确认，尚未产出正式设计稿，正式落地
  前建议交由设计师/设计工具精修月牙比例、位置等细节

### 启动页（Launch Screen）

- **设计方向**：与 App 图标视觉统一，延续"暮色紫极简新月"语言
  - 背景：纯色暮色紫 `#372f52`，不使用渐变
  - 主体：居中放大版月牙图标（与 App 图标同构），建立"点开即所见"
    的连贯感
  - 文字：中文主标题"闲眠" + 英文小号大写字母间距"UNHURRY"置于
    图标下方，作为品牌背书，克制不喧宾夺主
  - 不使用加载动画/进度条——启动页本质是静态占位图，加动画容易在
    切换到真实界面时产生跳动感
- **技术实现**：使用 LaunchScreen storyboard（或 iOS 14+ 的
  `UILaunchScreen` Info.plist 配置）实现，本质是简化静态布局，
  **不能包含真实动态逻辑**（无法在启动页做真正的音频播放/计时器
  动画），落地时直接用 Xcode 的 LaunchScreen.storyboard 或 SwiftUI
  启动配置搭建即可，无需额外生成图片资源

## 常用命令

项目尚未初始化 Xcode 工程，以下为工程建立后的常用命令模板，
创建工程后请替换为实际的 scheme/target 名称：

```bash
# 构建
xcodebuild -scheme SleepApp -destination 'platform=iOS Simulator,name=iPhone 16' build

# 运行测试
xcodebuild -scheme SleepApp -destination 'platform=iOS Simulator,name=iPhone 16' test

# 仅运行某个测试类
xcodebuild -scheme SleepApp -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:SleepAppTests/AudioServiceTests test

# SwiftLint（如引入）
swiftlint
```

## 音频内容策略

音频是本 App 的核心资产，内容来源与开发顺序已确定如下，Claude Code
在涉及音频相关任务时应遵循这些约定。

### 内容来源：以 AI 生成为主

- **环境音/白噪音类**（雨声、海浪、篝火、风声、白噪音等）优先使用
  AI 生成（如 ElevenLabs Sound Effects、Stable Audio 等），版权清晰，
  成本低，且可按需微调参数
- 纯白噪音/粉噪音/棕噪音可直接用算法生成（Audacity 或代码生成），
  零版权风险
- 语音引导类（冥想/睡前故事）短期可用 TTS（如 AVSpeechSynthesizer
  做原型验证，或 ElevenLabs 等做正式内容）过渡，长期考虑委托专业
  配音员制作核心招牌内容
- **禁止**未经确认使用来源不明或授权不清晰的音频素材，尤其是
  “看似免费”的网络下载素材，必须先确认 License 类型

### 音频与开发的先后顺序

不是"先做完 App 再做音频"，也不是"先做完全部音频再开发"，而是：

1. **先生成 2-3 个"种子音频"**（如雨声、白噪音）用于开发测试，
   不需要等音频库完整
2. **种子音频与 AudioService 核心功能同步开发磨合**——用真实音频
   验证混音、无缝循环、淡入淡出、后台播放等效果，避免用占位音频
   导致后期返工
3. **App 核心播放功能稳定后，再批量生成/处理剩余音频内容**
4. 后续新增音效或优化音质，可独立于 App 版本迭代（音频走云端加载
   时尤其如此，不需要每次都随 App 提审新版本）

### 音频处理要求

- AI 生成的音频通常也不是天然无缝循环，仍需人工在 Audacity 等工具
  中做首尾波形对齐处理
- 每个音频文件需要登记来源记录：生成工具/素材来源、生成日期、
  授权类型说明，便于审核与追溯（建议维护一份独立的授权记录表，
  不放在代码仓库中，避免和代码提交历史混淆）
- 格式统一转换为 `.m4a`（AAC），码率 96-128kbps

## 核心功能模块（开发优先级参考）

1. **音频播放引擎**（AudioService）— 所有功能的基础，优先实现
   - 支持多音轨混音、循环播放、淡入淡出
   - 后台持续播放（Info.plist 需声明 `UIBackgroundModes: audio`）
2. **睡眠计时器** — 定时渐弱停止播放
3. **白噪音/自然音库** — 音频资源管理，建议流式加载 + 本地缓存，
   不要把所有音频文件打包进 App 主 bundle
4. **睡前故事/冥想引导** — 音频 + 文字稿展示
5. **睡眠追踪** — HealthKit 读写睡眠分析数据，需要用户授权
6. **智能闹钟**（进阶）— 结合 HealthKit/CoreMotion 判断浅睡眠期

## 编码约定

- 遵循 Swift API 设计规范（Swift API Design Guidelines）
- 视图（View）保持轻量，业务逻辑放在 ViewModel
- 异步代码统一使用 `async/await`，避免嵌套 completion handler
- 音频相关的资源管理需注意内存/播放会话（AVAudioSession）冲突，
  尤其是混音场景下多个音轨同时播放的资源竞争
- 新增第三方依赖前先确认必要性，优先使用系统原生能力

## 需要人工确认的事项

以下内容涉及产品/业务决策，Claude 不应自行假设，需先与用户确认：

- 具体支持的 iOS 最低版本
- 商业模式（订阅制 / 免费+内购 / 买断）及对应的 StoreKit 集成方式
- 具体使用哪个 AI 音频生成工具/服务（需确认商用授权条款后再落地集成）
- 是否需要账号系统与云同步（涉及后端选型）
- HealthKit 权限的具体使用范围与隐私政策文案

## 测试要求

- 新增 Service 层逻辑（尤其 AudioService、HealthKitService）需配单元测试
- 音频播放相关功能优先在真机上验证（模拟器音频行为可能不一致）
- UI 变更需在浅色/深色模式下分别检查（助眠类 App 深色模式尤为重要）
