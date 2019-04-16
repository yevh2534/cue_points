//
//  TableViewController.swift
//  CuePointsTracker
//
//  Created by Yevhenii Lytvynenko on 3/28/19.
//  Copyright © 2019 Yevhenii Lytvynenko. All rights reserved.
//

import UIKit
import CuePointsTrackerEngine

class TableViewController: UITableViewController {
    
    private let _points: [Double] = {
        return [1.5, 1.6, 1.7, 1.8, 3, 4, 4.3, 4.32, 5, 10, 10.5]
    }()
    
    var points: [Double] = []
    
    var tracker: CuePointsTracker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tracker = CuePointsTrackeFactory.formTracker(delegate: self)
        tracker.add(cuePoints: _points)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return points.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(points[indexPath.row])s"
        return cell
    }

}

extension TableViewController: CuePointsTrackerDelegate {
    
    func tracker(_ tracker: CuePointsTracker, didRestoreCuePointsAt indexes: [Int]) {
        let pts = _points[indexes.first!...indexes.last!]
        points.removeAll(where: {pts.contains($0)})
        tableView.reloadData()
        print("didRestoreCuePointsAt \(indexes)")
    }
    
    func tracker(_ tracker: CuePointsTracker, didGoThroughCuePointsAt indexes: [Int]) {
        let pts = _points
        points.append(contentsOf: pts[indexes.first!...indexes.last!])
        tableView.reloadData()
        print("didGoThroughCuePointsAt \(indexes)")
    }
}
