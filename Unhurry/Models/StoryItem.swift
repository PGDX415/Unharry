//
//  StoryItem.swift
//  Unhurry
//

import Foundation

/// 睡前故事 / 冥想引导条目。
///
/// 包含全文内容（用于屏幕滚动展示）。
/// 支持两种播放模式：
/// - **TTS 模式**（`audioFileName == nil`）：使用 AVSpeechSynthesizer 实时合成语音
/// - **音频模式**（`audioFileName != nil`）：使用预录 AI 音频，文字稿同步高亮
struct StoryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let category: StoryCategory
    /// 简短描述
    let summary: String
    /// 全文内容（屏幕展示 + 进度同步）
    let content: String
    /// 预录音频文件名（不含扩展名），位于 Bundle 根目录。
    /// 非 nil 时优先播放音频而非 TTS。
    var audioFileName: String? = nil
    /// 预录音频扩展名
    var audioFileExtension: String = "mp3"

    /// 是否有预录音频
    var hasAudio: Bool { audioFileName != nil }

    /// 预估时长（秒）
    var estimatedDuration: TimeInterval {
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

    /// 内置故事列表。
    ///
    /// - `audioFileName` 非 nil → 播放预录音频
    /// - `audioFileName` 为 nil → 使用 TTS 朗读
    /// - 音频文件缺失时自动降级到 TTS
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
            """,
            audioFileName: "meditation_breath"
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
            """,
            audioFileName: "meditation_body_scan"
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
            """,
            audioFileName: "story_moon"
        ),
        StoryItem(
            id: "story_star",
            title: "星星的旅程",
            category: .story,
            summary: "一颗小星星穿越夜空，把睡意带给每个孩子",
            content: """
            天黑了，夜空中亮起了第一颗小星星。

            它眨眨眼睛，看看下面的大地——所有的房子都亮着温暖的灯光。

            小星星决定开始今晚的旅程。

            它飘过一座红色的屋顶。屋子里，一个小女孩刚刚洗完澡，头发还湿漉漉的。小星星轻轻吹了一口气，女孩打了个呵欠。

            它飘过一扇蓝色的窗户。窗台上，一只花猫蜷成一团。小星星在它耳边哼了一首摇篮曲，花猫的呼噜声更响了。

            它飘过一片安静的湖面。湖水像一面镜子，倒映着满天的星星。小星星在湖面上跳了一支舞，涟漪一圈一圈地散开。湖水也困了，波纹越来越小，越来越轻。

            最后，小星星来到了你的窗前。

            它趴在窗台上，用最轻柔的光照着你的脸。它看见你闭着眼睛，睫毛微微颤动。

            「你也在等我呀。」小星星开心地笑了。

            它把自己最亮的光芒收起来，只留下一点点温暖的光，像一盏小小的夜灯，守护在你的枕边。

            睡吧。小星星会一直在这里，直到天亮。
            """,
            audioFileName: "story_star"
        ),
        StoryItem(
            id: "story_cloud",
            title: "云上的家",
            category: .story,
            summary: "躺在柔软的云朵上，慢慢飘向梦乡",
            content: """
            你发现自己站在一片绿油油的草地上。

            抬起头，天空蓝得像洗过一样，飘着几朵又白又软的云。

            你伸出手，一朵小小的云飘了下来，停在你面前。它看起来像一块刚出炉的棉花糖，软软的，暖暖的。

            你轻轻地爬上去。云朵稳稳地托住了你，像一张全世界最舒服的床。

            云朵开始慢慢上升。草地变小了，房子变小了，整座城市变成了一个小小的模型，闪烁着点点灯光。

            风吹过你的脸颊，不冷不热，刚刚好。云朵带着你穿过一层薄薄的雾，空气里有一股淡淡的甜味，像夏天傍晚的栀子花。

            你躺在云朵上，感觉自己的身体越来越轻。手和脚都松开了，背也松开了，整个人像融化了一样陷进云朵里。

            云朵慢慢飘，慢慢飘。星星在你身边一颗一颗亮起来，像有人在深蓝色的天幕上撒了一把碎钻。

            你听见远处传来细细的歌声。那是月亮在唱摇篮曲。

            闭上眼睛吧。云朵会一直飘，一直飘。

            飘进你今晚最美的梦里。
            """,
            audioFileName: "story_cloud"
        ),
        StoryItem(
            id: "meditation_gratitude",
            title: "感恩入睡",
            category: .meditation,
            summary: "回顾一天中值得感恩的三件小事，带着温暖入睡",
            content: """
            闭上眼睛，做三次深长的呼吸。

            吸气……感受空气填满你的身体。
            呼气……把一天的疲惫缓缓释放。

            现在，我想邀请你做一件特别的事情。

            在你的脑海中，回放今天。像看电影一样，从早到晚，慢慢地过一遍。

            找到第一个让你感到温暖的瞬间。也许是一个微笑，也许是一杯热茶，也许是阳光洒在桌上的那一刻。抓住它。在心里对它说：谢谢你。

            找到了吗？很好。

            继续回放。找到第二个值得感恩的瞬间。也许是一句关心的话，也许是完成了某件小事，也许是看到了美丽的天空。无论多大或多小，只要它让你心里动了一下就够了。在心里对它说：谢谢你。

            最后一次，找到第三个瞬间。可能是你还活着，你还能呼吸，你还有这张温暖的床。这一刻，你的心脏在跳动，你的肺在呼吸。它们为你工作了一整天，没有休息。在心里对你的身体说：谢谢你。

            带着这三份感谢，让它们像三条温暖的小被子，轻轻地盖在你身上。

            你被感谢包围着。你被爱包围着。

            你是安全的。你是满足的。

            现在，让思绪慢慢飘走。像一片叶子落在水面上，随波而去。

            晚安。愿你梦到所有让你微笑的事。
            """,
            audioFileName: "meditation_gratitude"
        ),
    ]
}
