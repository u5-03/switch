//
//  String.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/18.
//

import Foundation

extension String {
    static var random: String {
        let length = Int.random(in: 0...300)
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

    func trimmed(characterSet: CharacterSet = .whitespaces) -> String {
        trimmingCharacters(in: characterSet)
    }
}
