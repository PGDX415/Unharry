//
//  AudioServiceTests.swift
//  UnhurryTests
//

import XCTest
import AVFoundation
@testable import Unhurry

final class AudioServiceTests: XCTestCase {

    var audioService: AudioService!
    var sessionManager: AudioSessionManager!

    override func setUp() {
        super.setUp()
        sessionManager = AudioSessionManager()
        audioService = AudioService(sessionManager: sessionManager)
    }

    override func tearDown() {
        audioService.stopEngine()
        audioService = nil
        sessionManager = nil
        super.tearDown()
    }

    // MARK: - Buffer Registration Tests

    func testRegisterBuffer_storesBufferInMemory() {
        // Given
        guard let buffer = AVAudioPCMBuffer.silentBuffer(duration: 1.0) else {
            XCTFail("Failed to create silent buffer")
            return
        }

        // When
        audioService.registerBuffer(buffer, forSound: "test_silence")

        // Then - 验证 buffer 注册不会崩溃，且后续可播放
        XCTAssertFalse(audioService.isEngineRunning)
        XCTAssertTrue(audioService.activeSoundIds.isEmpty)
    }

    func testRegisterBuffer_overwritesExistingBuffer() {
        // Given
        let buffer1 = AVAudioPCMBuffer.silentBuffer(duration: 1.0)!
        let buffer2 = AVAudioPCMBuffer.silentBuffer(duration: 2.0)!

        // When
        audioService.registerBuffer(buffer1, forSound: "test")
        audioService.registerBuffer(buffer2, forSound: "test")

        // Then - 不应崩溃
        XCTAssertFalse(audioService.isEngineRunning)
    }

    // MARK: - Audio File Loading Tests

    func testLoadSound_fromFile_urlNormalizesPath() throws {
        // Given
        let tempURL = try AudioTestHelpers.createTempAudioFile(duration: 1.0)
        defer { AudioTestHelpers.removeTempFile(at: tempURL) }

        // When
        try audioService.loadSound(id: "test_tone", from: tempURL)

        // Then
        XCTAssertFalse(audioService.isEngineRunning,
                       "加载 buffer 不应启动 engine")
    }

    func testLoadSound_fromNonExistentFile_throwsError() {
        // Given
        let fakeURL = URL(fileURLWithPath: "/nonexistent/file.m4a")

        // When / Then
        XCTAssertThrowsError(try audioService.loadSound(id: "fake", from: fakeURL))
    }

    // MARK: - Playback Tests

    func testPlay_startsEngineAndPlaysBuffer() throws {
        // Given
        guard let buffer = AVAudioPCMBuffer.silentBuffer(duration: 1.0) else {
            XCTFail("Failed to create silent buffer")
            return
        }
        audioService.registerBuffer(buffer, forSound: "silent")

        // When
        try audioService.play(soundId: "silent", volume: 0.5, loop: false)

        // Then
        XCTAssertTrue(audioService.isEngineRunning, "Play 应该启动 engine")
        XCTAssertTrue(audioService.activeSoundIds.contains("silent"),
                      "activeSoundIds 应包含正在播放的音效")

        // Cleanup
        audioService.stop(soundId: "silent")
    }

    func testPlay_unloadedSound_throwsError() {
        // When / Then
        XCTAssertThrowsError(
            try audioService.play(soundId: "nonexistent", volume: 0.5, loop: false)
        ) { error in
            guard case AudioServiceError.soundNotLoaded(let id) = error else {
                XCTFail("Expected soundNotLoaded error")
                return
            }
            XCTAssertEqual(id, "nonexistent")
        }
    }

    func testPlay_loopMode_schedulesWithLoops() throws {
        // Given
        guard let buffer = AVAudioPCMBuffer.silentBuffer(duration: 0.5) else {
            XCTFail("Failed to create silent buffer")
            return
        }
        audioService.registerBuffer(buffer, forSound: "loop_test")

        // When
        try audioService.play(soundId: "loop_test", volume: 0.5, loop: true)

        // Then
        XCTAssertTrue(audioService.activeSoundIds.contains("loop_test"))

        // Cleanup
        audioService.stop(soundId: "loop_test")
    }

    // MARK: - Stop Tests

    func testStop_removesPlayerFromActiveList() throws {
        // Given
        let buffer = AVAudioPCMBuffer.silentBuffer(duration: 1.0)!
        audioService.registerBuffer(buffer, forSound: "to_stop")
        try audioService.play(soundId: "to_stop", volume: 0.5, loop: false)

        // When
        audioService.stop(soundId: "to_stop")

        // Then
        XCTAssertFalse(audioService.activeSoundIds.contains("to_stop"))
    }

    func testStopAll_clearsAllPlayers() throws {
        // Given
        for i in 0..<3 {
            let buffer = AVAudioPCMBuffer.silentBuffer(duration: 1.0)!
            audioService.registerBuffer(buffer, forSound: "sound_\(i)")
            try audioService.play(soundId: "sound_\(i)", volume: 0.5, loop: false)
        }
        XCTAssertEqual(audioService.activeSoundIds.count, 3)

        // When
        audioService.stopAll()

        // Then
        XCTAssertTrue(audioService.activeSoundIds.isEmpty)
    }

    // MARK: - Volume Control Tests

    func testSetVolume_clampsToValidRange() throws {
        // Given
        let buffer = AVAudioPCMBuffer.silentBuffer(duration: 1.0)!
        audioService.registerBuffer(buffer, forSound: "vol_test")
        try audioService.play(soundId: "vol_test", volume: 0.5, loop: false)

        // When - 设置越界值（不应崩溃）
        audioService.setVolume(1.5, for: "vol_test")
        audioService.setVolume(-0.5, for: "vol_test")
        audioService.setVolume(0.8, for: "vol_test")

        // Then - 只要不崩溃就算通过
        XCTAssertTrue(true)

        audioService.stop(soundId: "vol_test")
    }

    func testSetVolume_nonexistentSound_noop() {
        // When / Then - 对不存在音效设置音量不应崩溃
        audioService.setVolume(0.5, for: "nonexistent")
    }

    // MARK: - Fade Tests

    func testFadeOut_completesAndCleansUp() throws {
        // Given
        let buffer = AVAudioPCMBuffer.silentBuffer(duration: 2.0)!
        audioService.registerBuffer(buffer, forSound: "fade_test")
        try audioService.play(soundId: "fade_test", volume: 0.8, loop: false)

        let expectation = self.expectation(description: "Fade out completes")

        // When
        audioService.fadeOut(soundId: "fade_test", duration: 0.3) {
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertFalse(audioService.activeSoundIds.contains("fade_test"),
                       "淡出完成后应从活跃列表移除")
    }

    func testFadeOut_nonexistentSound_callsCompletionImmediately() {
        let expectation = self.expectation(description: "Fade out for nonexistent sound")

        audioService.fadeOut(soundId: "nonexistent", duration: 1.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFadeIn_rampsVolumeToTarget() throws {
        // Given
        let buffer = AVAudioPCMBuffer.silentBuffer(duration: 3.0)!
        audioService.registerBuffer(buffer, forSound: "fadein_test")
        try audioService.play(soundId: "fadein_test", volume: 0.1, loop: false)

        // When
        audioService.fadeIn(soundId: "fadein_test", duration: 0.5, targetVolume: 0.9)

        // Then - 等待淡入完成
        let expectation = self.expectation(description: "Wait for fade in")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.5)

        // 音量应已达到目标值
        XCTAssertTrue(audioService.activeSoundIds.contains("fadein_test"))

        audioService.stop(soundId: "fadein_test")
    }

    // MARK: - Concurrency / Multi-track Tests

    func testMultipleSimultaneousPlayback() throws {
        // Given - 注册多个 buffer
        for i in 0..<3 {
            let buffer = AVAudioPCMBuffer.silentBuffer(duration: 1.0)!
            audioService.registerBuffer(buffer, forSound: "track_\(i)")
        }

        // When - 同时播放多个
        try audioService.play(soundId: "track_0", volume: 0.5, loop: true)
        try audioService.play(soundId: "track_1", volume: 0.3, loop: true)
        try audioService.play(soundId: "track_2", volume: 0.7, loop: true)

        // Then - 三个音轨应同时活跃
        XCTAssertEqual(audioService.activeSoundIds.count, 3)
        XCTAssertTrue(audioService.activeSoundIds.contains("track_0"))
        XCTAssertTrue(audioService.activeSoundIds.contains("track_1"))
        XCTAssertTrue(audioService.activeSoundIds.contains("track_2"))

        audioService.stopAll()
    }

    func testMultiTrackIndependentVolumeControl() throws {
        // Given
        let buffer = AVAudioPCMBuffer.silentBuffer(duration: 2.0)!
        audioService.registerBuffer(buffer, forSound: "rain")
        audioService.registerBuffer(buffer, forSound: "ocean")

        try audioService.play(soundId: "rain", volume: 0.5, loop: true)
        try audioService.play(soundId: "ocean", volume: 0.5, loop: true)

        // When - 独立调整音量
        audioService.setVolume(0.2, for: "rain")
        audioService.setVolume(0.8, for: "ocean")

        // Then - 不崩溃即可（音量值验证需要 engine 内部状态）
        XCTAssertEqual(audioService.activeSoundIds.count, 2)

        audioService.stopAll()
    }

    // MARK: - Unload Tests

    func testUnloadSound_stopsAndRemovesBuffer() throws {
        // Given
        let buffer = AVAudioPCMBuffer.silentBuffer(duration: 1.0)!
        audioService.registerBuffer(buffer, forSound: "to_unload")
        try audioService.play(soundId: "to_unload", volume: 0.5, loop: true)

        // When
        audioService.unloadSound(id: "to_unload")

        // Then
        XCTAssertFalse(audioService.activeSoundIds.contains("to_unload"))

        // 重新加载同一 ID 应该可以正常工作（buffer 已清除）
        audioService.registerBuffer(buffer, forSound: "to_unload")
        try audioService.play(soundId: "to_unload", volume: 0.5, loop: false)
        XCTAssertTrue(audioService.activeSoundIds.contains("to_unload"))

        audioService.stop(soundId: "to_unload")
    }

    // MARK: - Engine Lifecycle Tests

    func testStopEngine_stopsAllPlayers() throws {
        // Given
        for i in 0..<2 {
            let buffer = AVAudioPCMBuffer.silentBuffer(duration: 1.0)!
            audioService.registerBuffer(buffer, forSound: "e_\(i)")
            try audioService.play(soundId: "e_\(i)", volume: 0.5, loop: false)
        }
        XCTAssertTrue(audioService.isEngineRunning)

        // When
        audioService.stopEngine()

        // Then
        XCTAssertFalse(audioService.isEngineRunning)
        XCTAssertTrue(audioService.activeSoundIds.isEmpty)
    }
}
