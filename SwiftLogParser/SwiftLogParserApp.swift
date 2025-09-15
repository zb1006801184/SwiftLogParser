//
//  SwiftLogParserApp.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI
#if canImport(Moya)
import Moya
#endif

@main
struct SwiftLogParserApp: App {

    init() {
        Network.sharedConfig = NetworkConfig(
            globalHeadersProvider: {
                [
                    "Accept": "application/json",
                ]
            },
            timeout: 20,
            isLoggingEnabled: true
        )
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

