//
//  Dependencies.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/24.
//

import Foundation
import Dependencies

extension DependencyValues {
    var multipeerConnectivityClient: MultipeerConnectivityClient {
        get { self[MultipeerConnectivityClient.self] }
        set { self[MultipeerConnectivityClient.self] = newValue }
    }
}

extension MultipeerConnectivityClient: DependencyKey {
    public static let testValue = Self.live
    public static var liveValue = Self.live
}

