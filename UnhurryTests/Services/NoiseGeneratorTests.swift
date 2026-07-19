//
//  NoiseGeneratorTests.swift
//  UnhurryTests
//

import XCTest
import AVFoundation
@testable import Unhurry

final class NoiseGeneratorTests: XCTestCase {

    // MARK: - White Noise

    func testWhiteNoise_generatesCorrectFrameCount() {
        let duration: TimeInterval = 2.0
        let sampleRate: Double = 44100

        let buffer = NoiseGenerator.whiteNoise(duration: duration, sampleRate: sampleRate)

        XCTAssertNotNil(buffer)
        XCTAssertEqual(buffer?.frameLength, AVAudioFrameCount(duration * sampleRate))
        XCTAssertEqual(buffer?.format.channelCount, 1)
    }

    func testWhiteNoise_samplesAreWithinAmplitudeRange() {
        let buffer = NoiseGenerator.whiteNoise(duration: 1.0, amplitude: 0.5)

        guard let channelData = buffer?.floatChannelData?.pointee else {
            XCTFail("No channel data")
            return
        }

        let frameCount = Int(buffer!.frameLength)
        var hasNonZero = false
        for i in 0..<frameCount {
            let sample = channelData[i]
            XCTAssertGreaterThanOrEqual(sample, -0.5)
            XCTAssertLessThanOrEqual(sample, 0.5)
            if abs(sample) > 0.001 { hasNonZero = true }
        }
        XCTAssertTrue(hasNonZero, "白噪音不应全为零")
    }

    func testWhiteNoise_twoBuffersAreDifferent() {
        let buf1 = NoiseGenerator.whiteNoise(duration: 0.1)!
        let buf2 = NoiseGenerator.whiteNoise(duration: 0.1)!

        // 两个随机 buffer 不应完全相同
        let data1 = buf1.floatChannelData!.pointee
        let data2 = buf2.floatChannelData!.pointee
        var identical = true
        for i in 0..<Int(buf1.frameLength) {
            if data1[i] != data2[i] { identical = false; break }
        }
        XCTAssertFalse(identical)
    }

    // MARK: - Pink Noise

    func testPinkNoise_generatesCorrectFrameCount() {
        let buffer = NoiseGenerator.pinkNoise(duration: 1.5, sampleRate: 44100)

        XCTAssertNotNil(buffer)
        XCTAssertEqual(buffer?.frameLength, AVAudioFrameCount(1.5 * 44100))
    }

    func testPinkNoise_samplesWithinRange() {
        let buffer = NoiseGenerator.pinkNoise(duration: 0.5, amplitude: 0.4)

        guard let data = buffer?.floatChannelData?.pointee else {
            XCTFail("No channel data")
            return
        }

        let len = Int(buffer!.frameLength)
        for i in 0..<len {
            let s = data[i]
            XCTAssertGreaterThanOrEqual(s, -0.4)
            XCTAssertLessThanOrEqual(s, 0.4)
        }
    }

    // MARK: - Brown Noise

    func testBrownNoise_generatesCorrectFrameCount() {
        let buffer = NoiseGenerator.brownNoise(duration: 1.0)

        XCTAssertNotNil(buffer)
        XCTAssertEqual(buffer?.frameLength, AVAudioFrameCount(44100))
    }

    func testBrownNoise_isNotConstantZero() {
        let buffer = NoiseGenerator.brownNoise(duration: 1.0)

        guard let data = buffer?.floatChannelData?.pointee else {
            XCTFail("No channel data")
            return
        }

        var hasVariation = false
        let first = data[0]
        for i in 1..<min(1000, Int(buffer!.frameLength)) {
            if abs(data[i] - first) > 0.0001 { hasVariation = true; break }
        }
        XCTAssertTrue(hasVariation, "棕噪音应有幅度变化")
    }

    // MARK: - File I/O

    func testSaveToFile_createsReadableFile() throws {
        guard let buffer = NoiseGenerator.whiteNoise(duration: 0.5) else {
            XCTFail("Failed to generate noise")
            return
        }

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_noise_\(UUID().uuidString).caf")
        defer { try? FileManager.default.removeItem(at: url) }

        try NoiseGenerator.saveToFile(buffer: buffer, url: url)

        // 验证文件存在且可读
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let readFile = try AVAudioFile(forReading: url)
        XCTAssertEqual(readFile.length, Int64(buffer.frameLength))
    }
}
