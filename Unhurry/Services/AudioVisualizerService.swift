//
//  AudioVisualizerService.swift
//  Unhurry
//

import AVFoundation
import Accelerate

/// 音频频谱可视化服务。
///
/// 在 AVAudioEngine 主混音器节点上安装 tap，使用 vDSP FFT
/// 将 PCM 样本实时转换为频谱幅值，供 SwiftUI 视图渲染。
@MainActor
@Observable
final class AudioVisualizerService {

    // MARK: - Published

    /// 各频段的归一化幅值 (0...1)，共 `bandCount` 个元素。
    private(set) var magnitudes: [Float] = []

    /// 是否有音频信号（用于决定是否显示可视化）。
    private(set) var hasSignal = false

    // MARK: - Configuration

    private let bandCount: Int
    private let fftSize: Int

    // MARK: - FFT State

    private let fftSetup: FFTSetup
    private let log2n: vDSP_Length
    private var window: [Float]
    private var prevMagnitudes: [Float]
    private let smoothing: Float

    // MARK: - Tap State

    private nonisolated var isTapInstalled = false
    private nonisolated weak var mixerNode: AVAudioMixerNode?

    // MARK: - Init

    init(bandCount: Int = 24, fftSize: Int = 1024, smoothing: Float = 0.25) {
        self.bandCount = bandCount
        self.fftSize = fftSize
        self.smoothing = smoothing
        self.log2n = vDSP_Length(log2(Float(fftSize)))

        self.magnitudes = Array(repeating: 0, count: bandCount)
        self.prevMagnitudes = Array(repeating: 0, count: bandCount)

        // Hann 窗口
        self.window = (0..<fftSize).map { i in
            0.5 * (1 - cos(2 * .pi * Float(i) / Float(fftSize - 1)))
        }

        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            fatalError("Failed to create FFT setup")
        }
        self.fftSetup = setup
    }

    deinit {
        if isTapInstalled, let mixer = mixerNode {
            mixer.removeTap(onBus: 0)
        }
        vDSP_destroy_fftsetup(fftSetup)
    }

    // MARK: - Tap Lifecycle

    func start(on mixer: AVAudioMixerNode) {
        guard !isTapInstalled else { return }
        self.mixerNode = mixer

        let format = mixer.outputFormat(forBus: 0)
        mixer.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(fftSize),
            format: format
        ) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }
        isTapInstalled = true
    }

    func stop() {
        guard isTapInstalled, let mixer = mixerNode else { return }
        mixer.removeTap(onBus: 0)
        isTapInstalled = false
        mixerNode = nil
        magnitudes = Array(repeating: 0, count: bandCount)
        hasSignal = false
    }

    /// 静默重置（不解除 tap，仅归零 UI）。
    func resetDisplay() {
        magnitudes = Array(repeating: 0, count: bandCount)
        hasSignal = false
        prevMagnitudes = Array(repeating: 0, count: bandCount)
    }

    // MARK: - Audio Processing

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)

        // 拷贝样本（只取第一声道）
        var samples = [Float](repeating: 0, count: fftSize)
        let copyLength = min(frameLength, fftSize)
        samples.withUnsafeMutableBufferPointer { dest in
            let src = UnsafeBufferPointer(start: channelData[0], count: copyLength)
            for i in 0..<copyLength {
                dest[i] = src[i]
            }
        }

        // 捕获 self 需要的值（nonisolated）
        let capturedBandCount = bandCount
        let capturedFftSize = fftSize
        let capturedWindow = window
        let capturedSmoothing = smoothing
        let capturedFftSetup = fftSetup
        let capturedLog2n = log2n
        let capturedPrevMags = prevMagnitudes

        // 异步执行 FFT + 频段聚合 + 平滑
        Task.detached(priority: .utility) {
            let mags = AudioVisualizerService.computeBandMagnitudes(
                samples: samples,
                bandCount: capturedBandCount,
                fftSize: capturedFftSize,
                window: capturedWindow,
                fftSetup: capturedFftSetup,
                log2n: capturedLog2n,
                smoothing: capturedSmoothing,
                prevMagnitudes: capturedPrevMags
            )
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.magnitudes = mags
                self.hasSignal = mags.max() ?? 0 > 0.02
                self.prevMagnitudes = mags
            }
        }
    }

    /// 执行 FFT → 频段幅值聚合 → 平滑（static nonisolated，可在任意线程调用）。
    private static nonisolated func computeBandMagnitudes(
        samples: [Float],
        bandCount: Int,
        fftSize: Int,
        window: [Float],
        fftSetup: FFTSetup,
        log2n: vDSP_Length,
        smoothing: Float,
        prevMagnitudes: [Float]
    ) -> [Float] {
        let half = fftSize / 2

        // 1. 加 Hann 窗
        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(samples, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        // 2. 交错复数 → 分离复数
        var realParts = [Float](repeating: 0, count: half)
        var imagParts = [Float](repeating: 0, count: half)
        windowed.withUnsafeBytes { raw in
            let complexPtr = raw.bindMemory(to: DSPComplex.self)
            realParts.withUnsafeMutableBufferPointer { rp in
                imagParts.withUnsafeMutableBufferPointer { ip in
                    var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                    vDSP_ctoz(complexPtr.baseAddress!, 2, &split, 1, vDSP_Length(half))
                }
            }
        }

        // 3. FFT
        realParts.withUnsafeMutableBufferPointer { rp in
            imagParts.withUnsafeMutableBufferPointer { ip in
                var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(kFFTDirection_Forward))
            }
        }

        // 4. 计算幅值
        var mags = [Float](repeating: 0, count: half)
        realParts.withUnsafeMutableBufferPointer { rp in
            imagParts.withUnsafeMutableBufferPointer { ip in
                var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                vDSP_zvabs(&split, 1, &mags, 1, vDSP_Length(half))
            }
        }

        // 5. 频段聚合（对数刻度，低频分辨率更高）
        var bandMags = [Float](repeating: 0, count: bandCount)
        let nyquistBin = half - 1
        let sampleRate: Float = 44100

        for b in 0..<bandCount {
            let lowFreq = pow(10, Float(b) / Float(bandCount) * 3.0)
            let highFreq = pow(10, Float(b + 1) / Float(bandCount) * 3.0)
            let lowBin = max(0, Int(lowFreq / sampleRate * Float(nyquistBin * 2)))
            let highBin = min(nyquistBin, Int(highFreq / sampleRate * Float(nyquistBin * 2)))
            let count = highBin - lowBin
            if count > 0 {
                var sum: Float = 0
                mags.withUnsafeBufferPointer { ptr in
                    vDSP_sve(ptr.baseAddress! + lowBin, 1, &sum, vDSP_Length(count))
                }
                bandMags[b] = sum / Float(count)
            }
        }

        // 6. 归一化 + 对数压缩 + 指数平滑
        let maxMag = bandMags.max() ?? 1
        let scale: Float = maxMag > 0.001 ? 1.0 / maxMag : 0

        var prev = prevMagnitudes
        var result = [Float](repeating: 0, count: bandCount)
        for i in 0..<bandCount {
            let normalized = bandMags[i] * scale
            let compressed = log10(1 + normalized * 9)
            result[i] = prev[i] * (1 - smoothing) + compressed * smoothing
            prev[i] = result[i]
        }

        return result
    }
}
