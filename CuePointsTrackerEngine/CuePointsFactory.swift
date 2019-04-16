//
//  CuePointsFactory.swift
//  CuePointsTrackerEngine
//
//  Created by Yevhenii Lytvynenko on 3/26/19.
//  Copyright © 2019 Yevhenii Lytvynenko. All rights reserved.
//

import Foundation

public final class CuePointsTrackeFactory {
    public class func formTracker(delegate: CuePointsTrackerDelegate) -> CuePointsTracker {
        let executor = CancellableTaskExecutorImpl()
        let tracker = CuePointsTrackerImpl(executor: executor)
        tracker.delegate = delegate
        return tracker
    }
}
