//
//  MCMode.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import SwiftUI

enum MCMode {
    case sender
    case receiver

    var displayName: String {
        switch self {
        case .sender: return "送信モード"
        case .receiver: return "受信モード"
        }
    }

    var configColor: Color {
        switch self {
        case .sender: return .red
        case .receiver: return .blue
        }
    }
}
