//
//  String.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/18.
//

import SwiftUI
import CryptoKit

extension String {
    static var random: String {
        let length = Int.random(in: 0...10)
        return .random(length: length)
    }

    static func random(range: ClosedRange<Int>) -> String {
        return .random(length: Int.random(in: range))
    }

    static func random(length: Int) -> String {
        let length = Int.random(in: 0...10)
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ012345678"
        var randomString: String = ""

        for _ in 0...length {
            let randomValue = Int.random(in: 0 ... base.count - 1)
            let index: Index = base.index(base.startIndex, offsetBy: randomValue)
            let character: Character = base[index]
            randomString += String(character)
        }
        return randomString
    }

    var generatdBrightColor: Color {
        // 文字列をSHA256でハッシュ化
        let hash = SHA256.hash(data: self.data(using: .utf8)!)

        // ハッシュをData型に変換
        let hashData = Data(hash)

        // Dataの最初の6バイトを取得してRGBの色として使用
        let red = CGFloat(hashData[0]) / 255.0
        let green = CGFloat(hashData[1]) / 255.0
        let blue = CGFloat(hashData[2]) / 255.0

        // 明度を計算
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue

        // 明度が0.8以上（白に近い）場合、色を調整
        let adjustedRed = luminance >= 0.8 ? red * 0.7 : red
        let adjustedGreen = luminance >= 0.8 ? green * 0.7 : green
        let adjustedBlue = luminance >= 0.8 ? blue * 0.7 : blue

        return Color(red: adjustedRed, green: adjustedGreen, blue: adjustedBlue)
    }

    func trimmed(characterSet: CharacterSet = .whitespaces) -> String {
        trimmingCharacters(in: characterSet)
    }
}
