//===---*- ImageFeatGen -*-------------------------------------------------===//
//
// Comparing.swift
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
import Foundation
import CoreImage.CIFilterBuiltins

func compareImage(url: URL, inPlistURL plistURL: URL) throws {
    print("Comparing...")
    
    let imageData = try Data(contentsOf: url)
    guard let image = CIImage(data: imageData) else {
        print("error: Input URL is not an image")
        preconditionFailure()
    }
    
    let pairs = try PropertyListDecoder().decode(
        [FeaturePair].self,
        from: Data(contentsOf: plistURL)
    )
    
    let hasher = PHash(16, 4)
    var result: [(Double, FeaturePair)] = []
    
    let imageHash = hasher.compute(image)
    
    for pair in pairs {
        let distance = PHash.distance(from: pair.feature, to: imageHash)!
        result.append((distance, pair))
    }
    
    result.sort { $0.0 < $1.0 }
    for r in result.prefix(10) {
        print("\(String(format: "%.4f", r.0)): \(r.1.cardID)/\(r.1.trained)")
    }
}
