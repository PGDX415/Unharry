//
//  AudioVisualizerView.swift
//  Unhurry
//

import SwiftUI
import Combine

/// 频谱柱状图——平静的呼吸式动画，匹配助眠 App 氛围。
struct AudioVisualizerView: View {

    let magnitudes: [Float]
    let hasSignal: Bool

    @AppStorage("useBlackBackground") private var useBlackBg = false

    private var accentColor: Color { Theme.accentColor }

    /// 如果 5 秒内无信号，自动隐藏（保留占位空间避免布局跳动）
    @State private var lastSignalTime: Date = .distantPast
    @State private var isVisible = false

    private let barCount: Int
    private let maxHeight: CGFloat

    init(magnitudes: [Float], hasSignal: Bool, maxHeight: CGFloat = 80) {
        self.magnitudes = magnitudes
        self.hasSignal = hasSignal
        self.maxHeight = maxHeight
        self.barCount = magnitudes.count
    }

    var body: some View {
        VStack(spacing: 0) {
            if isVisible {
                barChart
                    .transition(.opacity)
            }
        }
        .frame(height: isVisible ? maxHeight + 12 : 0)
        .animation(.easeInOut(duration: 0.6), value: isVisible)
        .onChange(of: hasSignal) { _, newVal in
            if newVal {
                lastSignalTime = .now
                isVisible = true
            }
        }
        .onReceive(
            Timer.publish(every: 5, on: .main, in: .common).autoconnect()
        ) { _ in
            if isVisible && Date().timeIntervalSince(lastSignalTime) > 5 {
                isVisible = false
            }
        }
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                let mag = index < magnitudes.count
                    ? CGFloat(magnitudes[index])
                    : 0
                bar(magnitude: mag, index: index)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(height: maxHeight + 8, alignment: .bottom)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.opacity(0.04))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Single Bar

    private func bar(magnitude: CGFloat, index: Int) -> some View {
        let barHeight = max(2, magnitude * maxHeight)

        return RoundedRectangle(cornerRadius: 1.5)
            .fill(barColor(for: index))
            .frame(width: max(2, (UIScreen.main.bounds.width - 80) / CGFloat(barCount) - 2),
                   height: barHeight)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: barHeight)
    }

    /// 从左到右从低到高频，颜色渐变
    private func barColor(for index: Int) -> Color {
        let fraction = CGFloat(index) / CGFloat(max(1, barCount - 1))
        return accentColor.opacity(0.35 + Double(fraction) * 0.45)
    }
}

#Preview {
    VStack(spacing: 20) {
        AudioVisualizerView(
            magnitudes: (0..<24).map { Float.random(in: 0...1) * (Float($0) / 24) },
            hasSignal: true,
            maxHeight: 80
        )
        AudioVisualizerView(
            magnitudes: Array(repeating: 0, count: 24),
            hasSignal: false,
            maxHeight: 80
        )
    }
    .padding()
    .background(Color(red: 0.216, green: 0.184, blue: 0.322))
    .preferredColorScheme(.dark)
}
