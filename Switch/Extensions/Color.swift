//
//  Color.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/26.
//

import SwiftUI
#if os(iOS)
import UIKit
typealias AppColor = UIColor
#elseif os(macOS)
import AppKit
typealias AppColor = NSColor
#endif

extension Color {
    // 輝度に基づいて適切な文字色を返す関数
    var appropriateTextColor: Color {
        return luminance > 0.5 ? .black : .white
    }

    // 色の輝度を計算する関数
    private var luminance: Double {
        // RGBの各コンポーネントを取得
        let components = components
        let red = components.red
        let green = components.green
        let blue = components.blue

        // 輝度を計算
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }

    // ColorからRGBの各コンポーネントを取得する関数
    private var components: (red: Double, green: Double, blue: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        AppColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
        return (Double(red), Double(green), Double(blue))
    }

    static func rgb(red: Double, green: Double, blue: Double) -> Color {
        return Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
