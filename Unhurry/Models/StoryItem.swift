//
//  StoryItem.swift
//  Unhurry
//

import Foundation

/// 睡前故事 / 冥想引导条目。
///
/// 包含全文内容（用于 TTS 朗读 + 屏幕滚动展示）。
/// 后续阶段可扩展 `audioURL` 字段以替换 TTS 为预录音频。
struct StoryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let category: StoryCategory
    /// 简短描述
    let summary: String
    /// 全文内容（TTS 朗读 + 屏幕展示）
    let content: String
    /// 预估时长（秒），基于文本长度粗略估计
    var estimatedDuration: TimeInterval {
        // 中文 TTS 约每秒 3-4 字
        Double(content.count) / 3.5
    }
}

/// 故事分类
enum StoryCategory: String, CaseIterable, Identifiable {
    case meditation = "meditation"
    case story = "story"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meditation: return "冥想引导"
        case .story:      return "睡前故事"
        }
    }

    var iconName: String {
        switch self {
        case .meditation: return "sparkles"
        case .story:      return "book.fill"
        }
    }
}

// MARK: - 内置示例内容

extension StoryItem {

    /// 原型阶段的内置故事（TTS 朗读）。
    /// 后续替换为专业配音音频 + 文字稿。
    static let builtIn: [StoryItem] = [
        StoryItem(
            id: "meditation_breath",
            title: "呼吸放松",
            category: .meditation,
            summary: "5 分钟呼吸冥想，放下一天的疲惫",
            content: """
            请找一个舒服的姿势躺好，闭上眼睛。

            现在，把注意力放在你的呼吸上。

            吸气……感受空气缓缓进入你的身体。
            呼气……让所有的紧张随着呼气离开。

            吸气……想象气息像温暖的阳光，照亮你的胸腔。
            呼气……把一天的疲惫都呼出去。

            继续自然地呼吸。不需要刻意控制，只是观察它。

            如果你的思绪飘走了，没关系，温柔地把它带回到呼吸上。

            每一次呼吸，你都更加放松。
            每一次呼吸，你都更加平静。

            现在，从头顶开始，感受一股暖流慢慢流遍全身。
            额头放松，眉毛舒展。
            下巴放松，嘴唇微微分开。
            肩膀下沉，手臂自然垂落。
            胸口的起伏越来越平缓。
            腹部柔软，随着呼吸轻轻起伏。

            整个人像漂浮在温暖的湖面上，安全，舒适，宁静。

            带着这份平静，慢慢进入梦乡。
            晚安。
            """
        ),
        StoryItem(
            id: "meditation_body_scan",
            title: "身体扫描",
            category: .meditation,
            summary: "从头到脚逐步放松，引导进入深度睡眠",
            content: """
            躺下来，让自己完全交给床铺的支撑。

            从头顶开始，感受头皮是否紧绷。有意识地松开它。

            额头，眉毛，眼睛周围的肌肉，全部放松。

            脸颊，下巴，让牙齿轻轻分开。舌头顶在上颚，软软地放着。

            注意力移到脖子和肩膀。这里常常储存着一天的疲劳。让它们彻底放松，像融化了一样。

            手臂，从肩膀到手指尖，逐节地松开。想象手臂变得越来越重，陷入床垫里。

            胸口和腹部随着呼吸轻轻地起伏。每一次呼气，紧张就离开一点。

            背部，脊椎，腰，感受床铺准确地托着你的身体，你什么都不需要做，只需要放下。

            臀部，大腿，膝盖，小腿，脚踝，脚趾。全部沉下去，沉入柔软的床垫。

            现在，你的整个身体都已经完全放松。

            你安全、温暖、被这个世界温柔地包裹着。
            安心地睡吧。
            """
        ),
        StoryItem(
            id: "story_moon",
            title: "月亮的故事",
            category: .story,
            summary: "一个温柔的睡前小故事，关于月亮和孩子的对话",
            content: """
            很久很久以前，在一个小村庄里，有一个总是睡不着的小男孩。

            每天晚上，他躺在床上，翻来覆去，眼睛睁得大大的。

            有一天晚上，月亮从窗户探进头来，问：「小家伙，你怎么还不睡呀？」

            「月亮婆婆，我睡不着。我的脑子里有好多好多事情。」

            月亮笑了笑，说：「那你把它们都告诉我吧，我帮你保管着，等你睡醒了再还给你。」

            小男孩想了想，开始说：「今天我和小花吵架了，我很后悔。明天要考试，我有点紧张。还有，我答应帮奶奶浇花却忘了……」

            月亮安静地听着，把每一件心事都轻轻地收进自己的光芒里。

            小男孩说着说着，发现脑子里的事情越来越少，眼皮越来越重。

            「月亮婆婆……我好像……困了……」

            「那就睡吧，小家伙。明天醒来，太阳会叫你的。晚安。」

            小男孩闭上了眼睛，做了一个很长很甜的梦。

            从那以后，每当小男孩睡不着，他就会对着窗外的月亮说说心里话。他知道，月亮婆婆总是温柔地听着。
            """
        ),
    ]
}
