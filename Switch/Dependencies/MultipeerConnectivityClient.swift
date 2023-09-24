//
//  MultipeerConnectivityClient.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import Foundation

struct MultipeerConnectivityClient: Sendable {
    public var delegate: @Sendable () async -> AsyncStream<MultipeerConnectivityDelegateAction>

    static var live: MultipeerConnectivityClient {
        let task = Task<MultipeerConnectivitySendableBox, Never> { @MainActor in
            let manager = MCManager.shared
            let delegate = MultipeerConnectivityDelegate()
            manager.setDelegate(delegate: delegate)
            return .init(manager: manager, delegate: delegate)
        }

        return MultipeerConnectivityClient { @MainActor in
            let delegate = await task.value.delegate
            return AsyncStream<MultipeerConnectivityDelegateAction> { continuation in
                delegate.registerContinuation(continuation)
            }
        }
    }
}
