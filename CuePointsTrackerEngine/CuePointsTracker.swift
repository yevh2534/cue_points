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
    
    weak var delegate: CuePointsTrackerDelegate?
   
    var executor: CancellableTaskExecutor
  
    var cuePoints: [Double] = []
    
    init(executor: CancellableTaskExecutor) {
        self.executor = executor
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
        
        var seconds = seconds
        
        if let lastPoint = cuePoints.last, seconds > lastPoint {
            seconds = lastPoint
        } else if seconds < 0 {
            seconds = 0
        }
    
        guard let currentTime = currentTime, currentTime != seconds else {
            return
        }
        
        //Calculate start shifting (the purpose is update current time as dynamic state)
        if isPlaying {
            let shift = currentTime - seconds
            startDate = Date(timeInterval: shift, since: startDate!)
        } else {
            staticCurrentTime = seconds
        }
    
        if seconds > currentTime {
            //Calculate indexes
            if let start = cuePoints.firstIndex(where: { $0 > currentTime }),
                let end = cuePoints.lastIndex(where: { $0 <= seconds }),
                start <= end {
                delegate?.tracker(self, didGoThroughCuePointsAt: (start...end).map({$0}))
            }
            
        } else {
            if  let start = cuePoints.firstIndex(where: { $0 > seconds }),
                let end = cuePoints.lastIndex(where: { $0 <= currentTime }),
                start <= end {
                delegate?.tracker(self, didRestoreCuePointsAt: (start...end).map({$0}))
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
        guard let currentTime = currentTime,
              let nextPointIndex = cuePoints.firstIndex(where: { $0 > currentTime }) else {
                return
        }
        
        let delay = cuePoints[nextPointIndex] - currentTime
        executor.execute(after: delay) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.tracker(self, didGoThroughCuePointsAt: [nextPointIndex])
            self.startWaitingForNextPoint()
        }
    }
}
