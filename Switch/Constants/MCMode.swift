//
//  MCMode.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import SwiftUI

enum MCMode: Equatable {
    case host
    case guest

    var displayName: String {
        switch self {
        case .host: return "ホストモード"
        case .guest: return "参加者モード"
        }
    }

    var configColor: Color {
        switch self {
        case .host: return .red
        case .guest: return .blue
        }
    }
}
