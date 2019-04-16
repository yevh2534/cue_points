//
//  CuePointsTrackerMocks.swift
//  CuePointsTrackerEngineTests
//
//  Created by Yevhenii Lytvynenko on 3/26/19.
//  Copyright © 2019 Yevhenii Lytvynenko. All rights reserved.
//

import Foundation
@testable import CuePointsTrackerEngine

final class CancellableTaskExecutorMock: CancellableTaskExecutor {
    
    typealias ExecutionHandler = (TimeInterval) -> Void
    
    var executionCounter = 0
    var cancelCounter = 0
    
    private var onExecuteWithDelayHandler: ExecutionHandler?
    
    func onExecuteAfterDelay(do handler: @escaping ExecutionHandler) {
        onExecuteWithDelayHandler = handler
    }
    
    func execute(after delay: TimeInterval, handler: @escaping () -> Void) {
        executionCounter += 1
        onExecuteWithDelayHandler?(delay)
    }
    func cancel() {
        cancelCounter += 1
    }
}

final class CuePointsTrackerDelegateMock: CuePointsTrackerDelegate {
    typealias Handler = ([Int]) -> Void
    var restoreCounter = 0
    var goThroughCounter = 0
    
    private var restoreHandler: Handler?
    func onRestore(do handler: @escaping Handler) {
        restoreHandler = handler
    }
    
    private var goThroughHandler: Handler?
    func onGoThrough(do handler: @escaping Handler) {
        goThroughHandler = handler
    }
    
    func tracker(_ tracker: CuePointsTracker, didRestoreCuePointsAt indexes: [Int]) {
        restoreCounter += 1
        restoreHandler?(indexes)
    }
    
    func tracker(_ tracker: CuePointsTracker, didGoThroughCuePointsAt indexes: [Int]) {
        goThroughCounter += 1
        goThroughHandler?(indexes)
    }
}
