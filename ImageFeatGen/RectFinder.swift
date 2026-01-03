//===---*- ImageFeatGen -*-------------------------------------------------===//
//
// RectFinder.swift
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

import CoreImage
import Foundation
import CoreImage.CIFilterBuiltins

func findRects(in imageURL: URL) throws {
    let imageData = try Data(contentsOf: imageURL)
    guard let image = CIImage(data: imageData) else {
        print("error: input image is not image")
        return
    }
    
    let ctx = CIContext()
    let edgeImage = image.applyingFilter("CIPhotoEffectMono")
        .applyingFilter("CIEdges", parameters: [
            kCIInputIntensityKey: 2.0
        ])
    
    let width = Int(edgeImage.extent.width)
    let height = Int(edgeImage.extent.height)
    var _bitmap: [Float] = .init(repeating: 0, count: width * height)
    ctx.render(
        edgeImage,
        toBitmap: &_bitmap,
        rowBytes: width * MemoryLayout<Float>.size,
        bounds: .init(x: 0, y: 0, width: width, height: height),
        format: .Rf,
        colorSpace: nil
    )
    let bitmap = stride(from: 0, to: _bitmap.count, by: width).map {
        Array(_bitmap[$0..<min($0 + width, _bitmap.count)])
    }
    
    var verticalSpacing: Int?
    var firstMatchStartX: Int?
    var firstMatchStartY: Int?
    var sideLength: Int?
    vSpacingSearch: for column in 0..<width {
        var continuousHit = 0
        var secondMatchStart: Int?
        let content = bitmap.map { $0[column] }
        for (i, p) in content.enumerated() {
            if p > 0.3 {
                continuousHit += 1
                if continuousHit > (sideLength ?? 120) - 20 {
                    if sideLength == nil {
                        if firstMatchStartY == nil {
                            firstMatchStartX = column
                            firstMatchStartY = i - 100
                        }
                    } else {
                        if secondMatchStart == nil {
                            secondMatchStart = i - continuousHit
                            verticalSpacing = secondMatchStart! - firstMatchStartY! - sideLength!
                            break vSpacingSearch
                        }
                    }
                }
            } else {
                if firstMatchStartY != nil && sideLength == nil {
                    sideLength = continuousHit
                }
                continuousHit = 0
            }
        }
    }
    
    guard let verticalSpacing, let sideLength, let firstMatchStartX, let firstMatchStartY else {
        print("error: Could not find vertical spacing")
        fatalError()
    }
    var horizontalSpacing: Int?
    hSpacingSearch: for column in (firstMatchStartX + sideLength + sideLength / 10)..<width {
        var continuousHit = 0
        let content = bitmap.map { $0[column] }
        for p in content {
            if p > 0.3 {
                continuousHit += 1
                if continuousHit > sideLength - 20 {
                    horizontalSpacing = column - firstMatchStartX - sideLength
                    break hSpacingSearch
                }
            } else {
                continuousHit = 0
            }
        }
    }
    
    guard let horizontalSpacing else {
        print("error: Could not find horizontal spacing")
        fatalError()
    }
    
    var results: [CGRect] = []
    var startY = firstMatchStartY
    while startY + sideLength < height {
        var startX = firstMatchStartX
        while startX + sideLength < width {
            results.append(.init(x: startX, y: startY, width: sideLength, height: sideLength))
            startX += sideLength + horizontalSpacing
        }
        startY += sideLength + verticalSpacing
    }
    
    results = results.filter { result in
        var c = 0
        for l in bitmap[Int(result.minY)..<Int(result.maxY)].map({ $0[Int(result.minX)..<Int(result.maxX)] }) {
            for p in l {
                if p < 0.1 { c += 1 }
            }
        }
        return c < Int(result.width * result.height) - 10
    }
    
    for result in results {
        print(result)
    }
}
