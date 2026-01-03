//===---*- ImageFeatGen -*-------------------------------------------------===//
//
// PHash.swift
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
import Accelerate
import CoreImage.CIFilterBuiltins

class PHash {
    let hashSize: Int
    let highFreqFactor: Int
    let freqShift: Int
    
    init(_ hashSize: Int, _ highFreqFactor: Int, freqShift: Int = 0) {
        self.hashSize = hashSize
        self.highFreqFactor = highFreqFactor
        self.freqShift = freqShift
    }
    
    private let coreImageContext = CIContext()
    
    static func distance(from data1: Data, to data2: Data) -> Double? {
        guard data1.count == data2.count else { return nil }
        var distance = 0
        for (byte1, byte2) in zip(data1, data2) {
            distance += (byte1 ^ byte2).nonzeroBitCount
        }
        return Double(distance) / Double(data1.count * 8)
    }
    
    func compute(_ image: CIImage) -> Data {
        let dct = _compute_dct(image).flatMap { $0 }
        let median = median(of: dct)
        let bits = dct.map { $0 > median }
        return bitsToData(bits)
    }
    
    func _compute_dct(_ image: CIImage) -> [[Float]] {
        let imgSize = hashSize * highFreqFactor
        var image = rgb2Gray(image)
        image = image.transformed(
            by: .init(
                scaleX: CGFloat(imgSize) / image.extent.width,
                y: CGFloat(imgSize) / image.extent.height
            ),
            highQualityDownsample: true
        )
        let dct = dct(image, imgSize)
        return sliceDCT(dct, originalSize: imgSize)
    }
    
    private func rgb2Gray(_ image: CIImage) -> CIImage {
//        let filter = CIFilter.colorControls()
//        filter.inputImage = image
//        filter.saturation = 0
//        return filter.outputImage!
        
        return image.applyingFilter("CIPhotoEffectMono")
    }
    
    private func dct(_ image: CIImage, _ size: Int) -> [Float] {
        var pixels = Array<Float>(repeating: 0, count: size * size)
        
        coreImageContext.render(
            image,
            toBitmap: &pixels,
            rowBytes: size * MemoryLayout<Float>.size,
            bounds: .init(x: 0, y: 0, width: size, height: size),
            format: .Rf,
            colorSpace: nil
        )
        
        let dctSetup = vDSP_DCT_CreateSetup(nil, .init(size), .II)!
        
        var intermediate = Array<Float>(repeating: 0, count: size * size)
        var result = Array<Float>(repeating: 0, count: size * size)
        
        for i in 0..<size {
            let rowStart = i * size
            vDSP_DCT_Execute(
                dctSetup,
                Array(pixels[rowStart..<(rowStart + size)]),
                &intermediate[rowStart]
            )
        }
        
        var transposed = Array<Float>(repeating: 0, count: size * size)
        vDSP_mtrans(intermediate, 1, &transposed, 1, .init(size), .init(size))
        
        for i in 0..<size {
            let rowStart = i * size
            vDSP_DCT_Execute(
                dctSetup,
                Array(transposed[rowStart..<(rowStart + size)]),
                &result[rowStart]
            )
        }
        
        vDSP_mtrans(result, 1, &intermediate, 1, .init(size), .init(size))
        return intermediate
    }
    
    private func sliceDCT(
        _ dct: [Float],
        originalSize: Int
    ) -> [[Float]] {
        var subMatrix = [[Float]]()
        
        for r in freqShift..<(hashSize + freqShift) {
            var currentRow = [Float]()
            for c in freqShift..<(hashSize + freqShift) {
                let index = r * originalSize + c
                currentRow.append(dct[index])
            }
            subMatrix.append(currentRow)
        }
        
        return subMatrix
    }
    
    private func median(of array: [Float]) -> Float {
        guard !array.isEmpty else { return 0 }
        let sorted = array.sorted()
        let count = sorted.count
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }
    
    private func bitsToData(_ bits: [Bool]) -> Data {
        let byteCount = (bits.count + 7) / 8
        var bytes = [UInt8](repeating: 0, count: byteCount)
        
        for (index, bit) in bits.enumerated() {
            if bit {
                let byteIndex = index / 8
                let bitPosition = 7 - (index % 8)
                bytes[byteIndex] |= (1 << bitPosition)
            }
        }
        
        return Data(bytes)
    }
}
