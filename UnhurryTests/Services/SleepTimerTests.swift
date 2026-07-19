//
//  SleepTimerTests.swift
//  UnhurryTests
//

import XCTest
import AVFoundation
@testable import Unhurry

final class SleepTimerTests: XCTestCase {

    var audioService: AudioService!
    var sleepTimer: SleepTimer!

    override func setUp() {
        super.setUp()
        audioService = AudioService()
        sleepTimer = SleepTimer(audioService: audioService)
    }

    override func tearDown() {
        sleepTimer.cancel()
        audioService.stopEngine()
        sleepTimer = nil
        audioService = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState_notRunning() {
        XCTAssertFalse(sleepTimer.isRunning)
        XCTAssertEqual(sleepTimer.remainingTime, 0)
    }

    // MARK: - Start / Cancel

    func testStart_setsRunningState() {
        sleepTimer.start(duration: 5, fadeOutDuration: 2)
        XCTAssertTrue(sleepTimer.isRunning)
        XCTAssertGreaterThan(sleepTimer.remainingTime, 0)

        sleepTimer.cancel()
    }

    func testCancel_stopsRunning() {
        sleepTimer.start(duration: 5, fadeOutDuration: 2)
        XCTAssertTrue(sleepTimer.isRunning)

        sleepTimer.cancel()
        XCTAssertFalse(sleepTimer.isRunning)
        XCTAssertEqual(sleepTimer.remainingTime, 0)
    }

    func testStartTwice_cancelsPrevious() {
        sleepTimer.start(duration: 10, fadeOutDuration: 3)
        let firstRemaining = sleepTimer.remainingTime

        sleepTimer.start(duration: 5, fadeOutDuration: 2)
        XCTAssertTrue(sleepTimer.isRunning)
        // 新计时器剩余时间应小于旧计时器的初始值
        XCTAssertLessThan(sleepTimer.remainingTime, firstRemaining)

        sleepTimer.cancel()
    }

    // MARK: - Callbacks

    func testCallback_onTickIsCalled() {
        let tickExpectation = expectation(description: "Tick received")
        sleepTimer.onTick = { remaining in
            XCTAssertGreaterThan(remaining, 0)
            tickExpectation.fulfill()
        }

        sleepTimer.start(duration: 3, fadeOutDuration: 1)
        wait(for: [tickExpectation], timeout: 5.0)

        sleepTimer.cancel()
    }

    func testCallback_onFinishIsCalled() {
        let finishExpectation = expectation(description: "Timer finished")
        sleepTimer.onFinish = { finishExpectation.fulfill() }

        // 设定很短的计时以确保快速完成
        sleepTimer.start(duration: 1, fadeOutDuration: 0)
        wait(for: [finishExpectation], timeout: 5.0)

        XCTAssertFalse(sleepTimer.isRunning)
    }

    func testCallback_onCancelIsCalled() {
        let cancelExpectation = expectation(description: "Timer cancelled")
        sleepTimer.onCancel = { cancelExpectation.fulfill() }

        sleepTimer.start(duration: 5, fadeOutDuration: 1)
        sleepTimer.cancel()

        wait(for: [cancelExpectation], timeout: 2.0)
        XCTAssertFalse(sleepTimer.isRunning)
    }

    // MARK: - Fade Out Trigger

    func testFadeOut_triggersWhenRemainingTimeReachesFadeDuration() throws {
        // Given: 注册并播放一个声音
        guard let buffer = AVAudioPCMBuffer.silentBuffer(duration: 5.0) else {
            XCTFail("Failed to create buffer")
            return
        }
        audioService.registerBuffer(buffer, forSound: "test_timer")
        try audioService.play(soundId: "test_timer", volume: 0.5, loop: true)
        XCTAssertTrue(audioService.activeSoundIds.contains("test_timer"))

        let finishExpectation = expectation(description: "Fade + finish")
        sleepTimer.onFinish = { finishExpectation.fulfill() }

        // 设定 3 秒计时 + 1 秒淡出
        sleepTimer.start(duration: 3, fadeOutDuration: 1)
        wait(for: [finishExpectation], timeout: 8.0)

        // 计时结束后，声音应已被停止
        XCTAssertFalse(audioService.activeSoundIds.contains("test_timer"))
        XCTAssertFalse(sleepTimer.isRunning)
    }
}
