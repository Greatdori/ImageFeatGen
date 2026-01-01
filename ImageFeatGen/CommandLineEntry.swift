//===---*- ImageFeatGen -*-------------------------------------------------===//
//
// CommandLineEntry.swift
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
import ArgumentParser

@main
struct CommandLineEntry: AsyncParsableCommand {
    @Flag var action: Action
    @Option(name: [.long, .short]) var input: String? = nil
    @Option(name: [.long, .short]) var output: String? = nil
    @Option(name: [.long, .customShort("l")]) var featureList: String? = nil
    
    mutating func run() async throws {
        switch action {
        case .generate:
            guard let output else {
                print("error: Output path required")
                preconditionFailure()
            }
            try await generateFeatures(to: URL(filePath: output))
        case .compare:
            guard let input, let featureList else {
                print("error: Comparing requires an image input and a feature list")
                preconditionFailure()
            }
            try compareImage(
                url: URL(filePath: input),
                inPlistURL: URL(filePath: featureList)
            )
        case .save:
            guard let output else {
                print("error: Output path required")
                preconditionFailure()
            }
            try await saveImages(to: URL(filePath: output))
        }
    }
    
    enum Action: EnumerableFlag {
        case generate
        case compare
        case save
    }
}
