//===---*- ImageFeatGen -*-------------------------------------------------===//
//
// SaveImages.swift
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

import AppKit
import DoriKit
import Foundation
import CoreImage.CIFilterBuiltins

func saveImages(to destination: URL) async throws {
    guard let cards = await PreviewCard.all() else {
        fatalError("Failed to get card list")
    }
    
    var finishedCount = 0
    let total = cards.reduce(into: 0) { $0 += $1.thumbAfterTrainingImageURL == nil ? 1 : 2 }
    printProgressBar(0, total: total)
    
    try? FileManager.default.createDirectory(
        at: destination,
        withIntermediateDirectories: true
    )
    
    for card in cards {
        LimitedTaskQueue.shared.addTask {
            retry: for i in 1...5 {
                if let data = try? Data(contentsOf: card.thumbNormalImageURL) {
                    guard let image = CIImage(data: data) else {
                        print("\rwarning: Normal image data of card \(card.id) is not image")
                        break retry
                    }
                    try! data.write(to: destination.appending(path: "\(card.id)before.png"))
                    break retry
                } else if i == 5 {
                    print("\rwarning: Could not get normal image data of card \(card.id). Ignoring")
                }
            }
            DispatchQueue.main.async {
                finishedCount += 1
                printProgressBar(finishedCount, total: total)
            }
        }
        if let url = card.thumbAfterTrainingImageURL {
            LimitedTaskQueue.shared.addTask {
                retry: for i in 1...5 {
                    if let data = try? Data(contentsOf: url) {
                        guard let image = CIImage(data: data) else {
                            print("\rwarning: Trained image data of card \(card.id) is not image")
                            break retry
                        }
                        try! data.write(to: destination.appending(path: "\(card.id)after.png"))
                        break retry
                    } else if i == 5 {
                        print("\rwarning: Could not get trained image data of card \(card.id). Ignoring")
                    }
                }
                DispatchQueue.main.async {
                    finishedCount += 1
                    printProgressBar(finishedCount, total: total)
                }
            }
        }
    }
    
    await LimitedTaskQueue.shared.waitUntilAllFinished()
}
