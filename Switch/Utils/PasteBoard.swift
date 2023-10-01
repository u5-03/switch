//
//  PasteBoard.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/10/01.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class PasteBoard {
    static func copy(text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#elseif os(macOS)
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }
}
