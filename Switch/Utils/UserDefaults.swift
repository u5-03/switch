//
//  UserDefaults.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/27.
//

import Foundation

enum UserDefaultsKey: String {
    case isReadTextEnable
    case isGuestReadTextEnable
    case isReceiveMessageDisplayOnlyMode
    case userDisplayName
}

extension UserDefaults {
    var isReadTextEnable: Bool {
        get {
            return bool(forKey: UserDefaultsKey.isReadTextEnable.rawValue)
        }
        set {
            set(newValue, forKey: UserDefaultsKey.isReadTextEnable.rawValue)
        }
    }

    var isGuestReadTextEnable: Bool {
        get {
            return bool(forKey: UserDefaultsKey.isGuestReadTextEnable.rawValue)
        }
        set {
            setValue(newValue, forKey: UserDefaultsKey.isGuestReadTextEnable.rawValue)
        }
    }

    var isReceiveMessageDisplayOnlyMode: Bool {
        get {
            return bool(forKey: UserDefaultsKey.isReceiveMessageDisplayOnlyMode.rawValue)
        }
        set {
            setValue(newValue, forKey: UserDefaultsKey.isReceiveMessageDisplayOnlyMode.rawValue)
        }
    }

    var userDisplayName: String {
        get {
            return string(forKey: UserDefaultsKey.userDisplayName.rawValue).unwrapped("")
        }
        set {
            setValue(newValue, forKey: UserDefaultsKey.userDisplayName.rawValue)
        }
    }
}
