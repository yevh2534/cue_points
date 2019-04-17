//
//  ViewController.swift
//  CuePointsTracker
//
//  Created by Yevhenii Lytvynenko on 3/26/19.
//  Copyright © 2019 Yevhenii Lytvynenko. All rights reserved.
//

import UIKit
import CuePointsTrackerEngine

class ViewController: UIViewController {
    
    weak var tableVC: TableViewController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        tableVC = segue.destination as? TableViewController
    }
   
    @IBAction func back(_ sender: Any) {
        tableVC.tracker?.seek(to: (tableVC.tracker?.currentTime ?? 0) - 3)
    }
    
    @IBAction func play(_ sender: Any) {
        tableVC.tracker?.start()
    }
    
    @IBAction func pause(_ sender: Any) {
        tableVC.tracker?.pause()
    }
    @IBAction func forward(_ sender: Any) {
        tableVC.tracker?.seek(to: (tableVC.tracker?.currentTime ?? 0) + 3)
    }
}
