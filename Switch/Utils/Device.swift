//
//  Device.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/22.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum Device {
    // Ref: https://levelup.gitconnected.com/device-information-in-swift-eef45be38109
    static var marketingName: String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return modelCode
    }

    static var name: String {
#if os(iOS)
        return UIDevice.current.name
#elseif os(macOS)
        return Host.current().name ?? "Mac"
#endif
    }
}
