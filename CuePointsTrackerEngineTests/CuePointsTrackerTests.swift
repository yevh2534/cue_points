//
//  CuePointsTrackerEngineTests.swift
//  CuePointsTrackerEngineTests
//
//  Created by Yevhenii Lytvynenko on 3/26/19.
//  Copyright © 2019 Yevhenii Lytvynenko. All rights reserved.
//

import XCTest

@testable import CuePointsTrackerEngine

class CuePointsTrackerTests: XCTestCase {

    func test_addPoints_StoresNewPointsAtTheEndOfArray() {
        let result = makeSut(withPointsCount: 2)
        XCTAssertEqual(result.sut.cuePoints.count, 2)
    }
    
    func test_start_executorWillNotBeStartedWhilePointsListIsEmpty() {
        let result = makeSut(withPointsCount: 3)
        XCTAssertEqual(result.executor.executionCounter, 0)
        result.sut.start()
        XCTAssertEqual(result.executor.executionCounter, 1)
    }
    
    func test_startWithOneCuePoint_willPassCorrectIntervalToExecutor() {
        let result = makeSut(withPointsCount: 1)
        result.executor.onExecuteAfterDelay { interval in
            XCTAssertEqual(interval.rounded(), result.sut.cuePoints.first?.rounded())
        }
        result.sut.start()
    }
    
    func test_startWithTwoCuePoint_willPassCorrectIntervalToExecutor() {
        let result = makeSut(withPointsCount: 2)
        result.executor.onExecuteAfterDelay { interval in
            XCTAssertEqual(interval.rounded(), result.sut.cuePoints.first?.rounded())
        }
        result.sut.start()
    }
    
    func test_startTimeIsCorrectAfterStart() {
        let result = makeSut(withPointsCount: 1)
        result.sut.start()
        XCTAssertEqual(result.sut.startDate!.timeIntervalSince1970.rounded(), Date().timeIntervalSince1970.rounded())
    }
    
    func test_currentTimeIsCorrectAfterStart() {
        let result = makeSut(withPointsCount: 3)
        result.sut.start()
        let exp = expectation(description: "Test after 2 seconds")
        let waitResult = XCTWaiter.wait(for: [exp], timeout: 2)
        if waitResult == XCTWaiter.Result.timedOut {
            XCTAssertEqual(result.sut.currentTime?.rounded(), 2)
        } else {
            XCTFail("Delay interrupted")
        }
    }
    
    //MARK: - Seek
    
    func test_seekToCurrentTimeDoNothing() {
        let result = makeSut(withPointsCount: 10)

        XCTAssertEqual(result.delegate.goThroughCounter, 0)
        XCTAssertEqual(result.delegate.restoreCounter, 0)

        result.sut.start()

        result.sut.seek(to: result.sut.currentTime!)

        XCTAssertEqual(result.delegate.goThroughCounter, 0)
        XCTAssertEqual(result.delegate.restoreCounter, 0)
    }
    
    func test_seekToSeconds_invokeDelegateMethods() {
        let result = makeSut(withPointsCount: 10)
        result.sut.start()
       
        result.sut.seek(to: result.sut.cuePoints.last! + 1)
        XCTAssertEqual(result.delegate.goThroughCounter, 1)
       
        result.sut.seek(to: 0)
        XCTAssertEqual(result.delegate.restoreCounter, 1)
    }
    
    func test_seekToSeconds_changeCurrentTime() {
        let result = makeSut(withPointsCount: 10)
        result.delegate.onGoThrough { indexes in
            let lastPoint = result.sut.cuePoints[indexes.last!]
            XCTAssertEqual(lastPoint, result.sut.currentTime?.rounded())
        }
        result.sut.start()
        result.sut.seek(to: result.sut.cuePoints.last!)
    }
    
    func test_seekToSeconds_passCorrectPointsToDelegate() {
        
        let result = makeSut(withPointsCount: 10)
        
        result.sut.start()
        
        //Seek from 0th to 4th points : Expect going through points with indexes (0, 1, 2, 3, 4)

        result.delegate.onGoThrough { indexes in
            XCTAssertEqual(indexes, (0...4).map({$0}))
        }
        result.sut.seek(to: result.sut.cuePoints[4])
        
        //Seek from 4th to 2th point : Expect restoring points with indexes (3, 4)

        result.delegate.onRestore { indexes in
            XCTAssertEqual(indexes, (3...4).map({$0}))
        }
        result.sut.seek(to: result.sut.cuePoints[2])
    }
    
    func test_seekToNegativeTime_willSeekToZero() {
        let result = makeSut(withPointsCount: 10)
        result.sut.start()
        
        result.sut.seek(to: -10)
        
        XCTAssertEqual(result.sut.currentTime?.rounded(), 0)
    }
    
    func test_seekOverTheEnd_willSeekToTheEnd() {
        let result = makeSut(withPointsCount: 10)
        result.sut.start()
        result.sut.seek(to: result.sut.cuePoints.last! + 20)
        XCTAssertEqual(result.sut.currentTime?.rounded(), result.sut.cuePoints.last!)
    }
    
    func test_seekOverTheEnd_currentTimeIsEqualToLastPointTime() {
        let result = makeSut(withPointsCount: 10)
        result.sut.start()
        result.sut.seek(to: result.sut.cuePoints.last! + 20)
        
        XCTAssertEqual(result.sut.cuePoints.last, result.sut.currentTime)
    }
    
    func test_seekWhenPaused_updatesCurrentTime() {
        let result = makeSut(withPointsCount: 10)
        result.sut.start()
        result.sut.pause()
        
        let time = result.sut.cuePoints[3]
        
        //Seek to 4th : Expects
        result.sut.seek(to: time)
        
        XCTAssertEqual(result.sut.currentTime?.rounded(), time)
    }
    
    func test_seekWhenPaused_passedCorectPointsToTheDelegate() {
        let result = makeSut(withPointsCount: 10)
        result.sut.start()
        
        result.sut.pause()
        
        
        //Seek from 0th to 4th point : Expects go through points with indexes (0, 1, 2, 3)
        result.delegate.onGoThrough { indexes in
            XCTAssertEqual(indexes, (0...3).map({ $0 }))
        }
        result.sut.seek(to: result.sut.cuePoints[3])
        
        //Seek from 4th to 1th : Expects restore points with indexes (2, 3)
        
        result.delegate.onRestore { indexes in
            XCTAssertEqual(indexes, (2...3).map({ $0 }))
        }
        result.sut.seek(to: result.sut.cuePoints[1])
    }
    
    //MARK: Pause
    
    func test_staticCurrentTimeWhenPaused_changeCurrentTime() {
        let result = makeSut(withPointsCount: 10)
        result.sut.start()
        result.sut.pause()
        let currentTime = result.sut.currentTime!
        
        let exp = expectation(description: "Test after 3 seconds")
        let waitResult = XCTWaiter.wait(for: [exp], timeout: 3)
        
        if waitResult == XCTWaiter.Result.timedOut {
            XCTAssertEqual(result.sut.currentTime?.rounded(), currentTime.rounded())
        } else {
            XCTFail("Delay interrupted")
        }
    }
    
    //MARK: - Helpers
    
    private func makeSut(withPointsCount count: Int = 0) -> (sut: CuePointsTrackerImpl, executor: CancellableTaskExecutorMock, delegate: CuePointsTrackerDelegateMock) {
        let executorSpy = CancellableTaskExecutorMock()
        let sut = CuePointsTrackerImpl(executor: executorSpy)
        sut.add(cuePoints: (1...count).map({Double($0)}))
        let delegate = CuePointsTrackerDelegateMock()
        sut.delegate = delegate
        return (sut: sut, executor: executorSpy, delegate: delegate)
    }
}
