//
//  CuePointsCancellableExecutor.swift
//  CuePointsTrackerEngine
//
//  Created by Yevhenii Lytvynenko on 3/26/19.
//  Copyright © 2019 Yevhenii Lytvynenko. All rights reserved.
//

import Foundation

protocol CancellableTaskExecutor {
    func execute(after delay: TimeInterval, handler: @escaping () -> Void)
    func cancel()
}

final class CancellableTaskExecutorImpl: CancellableTaskExecutor {
    
    //MARK: - Private vars
    
    private var counter = 0
    
    //MARK: - CancellableTaskExecutor
    
    func execute(after delay: TimeInterval, handler: @escaping () -> Void) {
        cancel()
        
        let currentCounter = counter
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) { [weak self] in
            guard let `self` = self else { return }
            if self.counter != currentCounter { return }
            handler()
        }
    }
    
    func cancel() {
        counter = counter > 100 ? 0 : counter + 1
    }
}
