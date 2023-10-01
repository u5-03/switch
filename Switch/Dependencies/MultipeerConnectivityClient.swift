//
//  MultipeerConnectivityClient.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import Foundation
import MultipeerConnectivity

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

    static var mock: MultipeerConnectivityClient {
        return MultipeerConnectivityClient { @MainActor in
            return AsyncStream<MultipeerConnectivityDelegateAction> { continuation in
                Task.detached {
                    while true {
                        // 1秒待機
                        try! await Task.sleep(for: .seconds(1))

                        // 値を流す
                        let stringData = String.random.data(using: .utf8) ?? Data()
                        let peerId = MCPeerID(displayName: .random(range: 1...10))
                        continuation.yield(MultipeerConnectivityDelegateAction.sessionDidReceived(data: stringData, peerID: peerId))
                    }
                }
            }
        }
    }
}
