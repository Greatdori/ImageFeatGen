//===---*- ImageFeatGen -*-------------------------------------------------===//
//
// ProgressBar.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2026 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import Foundation

func printProgressBar(_ progress: Int, total: Int) {
    func terminalWidth() -> Int {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            return Int(w.ws_col)
        } else {
            return 80
        }
    }
    
    let width = terminalWidth()
    let reservedSpace = 8
    let barLength = max(10, width - reservedSpace)
    let progress = Double(progress) / Double(total)
    let percent = Int(progress * 100)
    let filledLength = Int(progress * Double(barLength))
    let bar = String(repeating: "█", count: filledLength) + String(repeating: "-", count: barLength - filledLength)
    print("\r[\(bar)] \(percent)%", terminator: "")
    fflush(stdout)
}
