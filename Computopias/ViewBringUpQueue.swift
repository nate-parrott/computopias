//
//  ViewBringUpQueue.swift
//  Computopias
//
//  Created by Nate Parrott on 4/9/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ViewBringUpQueue: NSObject {
    static let Shared = ViewBringUpQueue()
    override init() {
        super.init()
        link = CADisplayLink(target: self, selector: #selector(ViewBringUpQueue._displayLink))
        link.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    var link: CADisplayLink!
    func _displayLink() {
        _timeElapsedWorkingThisFrame = 0
        _doWork()
    }
    var _timeElapsedWorkingThisFrame: CFAbsoluteTime = 0
    var _doingWork = false
    func _doWork() {
        _doingWork = true
        let started = CFAbsoluteTimeGetCurrent()
        while _timeElapsedWorkingThisFrame + (CFAbsoluteTimeGetCurrent() - started) < _timeAllotmentPerFrame && _tasks.count > 0 {
            _tasks.removeFirst()()
        }
        // print("Leaving \(_tasks.count) tasks for later")
        _timeElapsedWorkingThisFrame += CFAbsoluteTimeGetCurrent() - started
        _doingWork = false
    }
    var _timeAllotmentPerFrame: CFAbsoluteTime = 0.0005
    typealias Task = () -> ()
    var _tasks = [Task]()
    func addTask(task: Task) {
        _tasks.append(task)
        if !_doingWork {
            _doWork()
        }
    }
}
