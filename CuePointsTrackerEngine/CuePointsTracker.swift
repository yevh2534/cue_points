//
//  CuePointsTracker.swift
//  CuePointsTrackerEngine
//
//  Created by Yevhenii Lytvynenko on 3/26/19.
//  Copyright © 2019 Yevhenii Lytvynenko. All rights reserved.
//

import Foundation

public protocol CuePointsTracker {
    var currentTime: TimeInterval? { get }
    func start()
    func pause()
    func seek(to seconds: Double)
    func add(cuePoints: [Double])
    //TODO: Add method for Removing cue points
}

public protocol CuePointsTrackerDelegate: class {
    func tracker(_ tracker: CuePointsTracker, didRestoreCuePointsAt indexes: [Int])
    func tracker(_ tracker: CuePointsTracker, didGoThroughCuePointsAt indexes: [Int])
}

class CuePointsTrackerImpl: CuePointsTracker {
    
    //MARK: Private vars
    
    var startDate: Date?
    
    private var isPlaying: Bool = false {
        didSet {
            if isPlaying == oldValue { return }
            if isPlaying {
                if startDate == nil {
                    //First play : set start date to now (current time will be equal to zero)
                    startDate = Date()
                } else {
                    //Play after pause : adjust start date rely to staticCurrentTime
                    startDate = Date(timeIntervalSinceNow: staticCurrentTime * -1)
                }
            } else {
                //Playing is paused so staticCurrentTime have to be updated
                staticCurrentTime = Date().timeIntervalSince(startDate!)
            }
        }
    }
    
    private var staticCurrentTime: TimeInterval = 0
    
    private var executor: CancellableTaskExecutor
    
    private(set) var cuePoints: [Double] = []
    
    private let minDelegateInvokationInterval: Double
    
    var lastSentPointIndex: Int?
    
    //MARK: Public vars
    
    weak var delegate: CuePointsTrackerDelegate?
    
    //MARK: - Initialization
    
    init(executor: CancellableTaskExecutor, minDelegateInvokationInterval: Double = 0.5) {
        self.executor = executor
        self.minDelegateInvokationInterval = minDelegateInvokationInterval
    }
    
    //MARK: - CuePointsTracker
    
    var currentTime: TimeInterval? {
        guard let startDate = startDate else {
            return nil
        }
        var onPlayingTime = Date().timeIntervalSince(startDate)
        if let lastPoint = cuePoints.last, onPlayingTime > lastPoint {
            onPlayingTime = lastPoint
            self.startDate = Date(timeIntervalSinceNow: onPlayingTime * -1)
        }
        
        return isPlaying ? onPlayingTime : staticCurrentTime
    }
    
    func start() {
        if cuePoints.isEmpty || isPlaying { return }
        isPlaying = true
        startWaitingForNextPoint()
    }
    
    func pause() {
        //TODO: Set isPlaying to FALSE
        isPlaying = false
        executor.cancel()
    }
    
    func seek(to seconds: Double) {
        
        executor.cancel()
        
        var correctedSeconds = seconds
        
        if let lastPoint = cuePoints.last, correctedSeconds > lastPoint {
            correctedSeconds = lastPoint
        } else if seconds < 0 {
            correctedSeconds = 0
        }
        
        guard let currentTime = currentTime, currentTime != seconds else {
            return
        }
        
        //Calculate start shifting (the purpose is update current time as dynamic state)
        if isPlaying {
            let shift = currentTime - correctedSeconds
            startDate = Date(timeInterval: shift, since: startDate!)
        } else {
            staticCurrentTime = correctedSeconds
        }
        
        if let indices = indicesForPoints(currentTime: currentTime, destinationTime: seconds),
            let firstIndex = indices.first,
            let lastIndex = indices.last {
            
            let isForward = seconds > currentTime
            
            if isForward {
                self.delegate?.tracker(self, didGoThroughCuePointsAt: indices)
                self.lastSentPointIndex = lastIndex
            } else {
                self.delegate?.tracker(self, didRestoreCuePointsAt: indices)
                self.lastSentPointIndex = firstIndex > 0 ? firstIndex - 1 : nil
            }
        }
        
        if isPlaying {
            startWaitingForNextPoint()
        }
        
    }
    
    func add(cuePoints: [Double]) {
        self.cuePoints.append(contentsOf: cuePoints)
    }
    
    //MARK: - Helpers
    
    private func startWaitingForNextPoint() {
        
        guard let currentTime = currentTime else {
            return
        }
        
        guard let start = startIndexForForwarding() else { return }
        
        let nextPointIndex = cuePoints.firstIndex(where: { $0 > currentTime + minDelegateInvokationInterval }) ?? cuePoints.count - 1
        
        let delay = cuePoints[nextPointIndex] - currentTime
        
        executor.execute(after: delay) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.tracker(self, didGoThroughCuePointsAt: (start...nextPointIndex).map({$0}))
            self.lastSentPointIndex = nextPointIndex
            self.startWaitingForNextPoint()
        }
    }
    
    func indicesForPoints(currentTime: Double, destinationTime: Double) -> [Int]? {
        
        var start: Int?
        var end: Int?
        
        let isForward = destinationTime > currentTime
        
        //Find End of indices range
        if isForward {
            guard let startIndexForForwarding = startIndexForForwarding() else {
                return nil
            }
            start = startIndexForForwarding
            let slice = cuePoints[start!...]
            end = slice.lastIndex(where: { $0 <= destinationTime })
            
        } else {
            if let lastSentPointIndex = lastSentPointIndex {
                end = lastSentPointIndex
            } else {
                //No points to back
                return nil
            }
            
            let slice = cuePoints[...end!]
            start = slice.firstIndex(where: { $0 > destinationTime })
        }
        
        guard let firstIndex = start, let lastIndex = end, lastIndex >= firstIndex else {
            return nil
        }
        
        return (firstIndex...lastIndex).map({ $0 })
    }
    
    private func startIndexForForwarding() -> Int? {
        var start: Int?
        if let lastSentPointIndex = lastSentPointIndex {
            if lastSentPointIndex < cuePoints.count - 1 {
                start = lastSentPointIndex + 1
            } else {
                //No points to forward
                start = nil
            }
        } else {
            start = 0
        }
        return start
    }
    
}
