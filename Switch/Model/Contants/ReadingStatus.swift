//
//  ReadingStatus.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/18.
//

import Foundation
import SwiftUI

enum ReadingStatus {
    case reading
    case readCompleted
    case willRead
    case readingError

    var color: Color {
        switch self {
        case .reading:
            return .yellow
        case .readCompleted:
            return .blue
        case .willRead:
            return .green
        case .readingError:
            return .red
        }
    }
}
