//
//  Synchronized.swift
//  MTGTethering
//
//  Created by Schumacher Clay on 4/10/16.
//
//

import Foundation

func synchronized<T>(_ lockOn: AnyObject!, closure: () -> T) -> T {
    objc_sync_enter(lockOn)
    defer{ objc_sync_exit(lockOn) }
    return closure()
}
