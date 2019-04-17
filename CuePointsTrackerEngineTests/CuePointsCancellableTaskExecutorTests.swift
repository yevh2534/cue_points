//
//  CuePointsCancellableTaskExecutorTests.swift
//  CuePointsTrackerEngineTests
//
//  Created by Yevhenii Lytvynenko on 3/26/19.
//  Copyright © 2019 Yevhenii Lytvynenko. All rights reserved.
//

import XCTest
@testable import CuePointsTrackerEngine

class CuePointsCancellableTaskExecutorTests: XCTestCase {

    func test_executeAfteDelay_timeIntervalIsCorrect() {
        let sut = CancellableTaskExecutorImpl()
        
        let timeOut: TimeInterval = 1
        let exp = expectation(description: "Handler")
        
        sut.execute(after: timeOut) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: timeOut)
    }
    
    func test_cancel_taskWillNotBeExecuted() {
        let sut = CancellableTaskExecutorImpl()
       
        let exp = expectation(description: "Handler")
        exp.isInverted = true
        
        let timeOut: TimeInterval = 1
        
        sut.execute(after: timeOut) {
            exp.fulfill()
        }
        sut.cancel()
       
        wait(for: [exp], timeout: timeOut)
    }
    
    func test_executeBeforeLastExecution_lastExecutionWillBeCancelled() {
        
        let sut = CancellableTaskExecutorImpl()
        
        let exp = expectation(description: "Handler")
        
        let timeOut: TimeInterval = 1
        
        sut.execute(after: timeOut + 1) {
            exp.fulfill()
        }
        
        sut.execute(after: timeOut + 2) {
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: timeOut + 3)
    }

}
