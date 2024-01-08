//
//  SharedStateReducer.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/11/08.
//

import Foundation
import MultipeerConnectivity
import ComposableArchitecture
import Combine

struct PeerInfo: Identifiable, Equatable {
    let id = UUID().uuidString
    let peerId: MCPeerID
}

//struct SharedStateReducer: Reducer {
//    typealias Action = SharedAction
//    struct State: Equatable {
//        var multipeerConnectivityState: MultipeerConnectivityState?
//        var connectedPeerInfos: [PeerInfo] = []
//        var isReadTextEnable = false {
//            didSet {
//                print("")
//                UserDefaults.standard.isReadTextEnable.toggle()
//            }
//        }
//
//
//        //        var isReceiveMessageDisplayOnlyMode = false {
//        //            didSet {
//        //                UserDefaults.standard.isReceiveMessageDisplayOnlyMode.toggle()
//        //            }
//        //        }
//    }
//
//
//    func reduce(into state: inout State, action: Action) -> Effect<Action> {
//        switch action {
//        case .didUpdatedConnectedPeerInfos(let connectedPeerInfos):
//            state.connectedPeerInfos = connectedPeerInfos
//        case .toggleReceiveMessageDisplayOnlyMode:
//            UserDefaults.standard.isReceiveMessageDisplayOnlyMode.toggle()
//            //            state.isReceiveMessageDisplayOnlyMode.toggle()
//        case .toggleReadTextEnable:
//            state.isReadTextEnable.toggle()
//        }
//        return .none
//    }
//}

enum SharedAction {
    case didUpdatedConnectedPeerInfos([PeerInfo])
    case toggleReceiveMessageDisplayOnlyMode
    case toggleReadTextEnable
}

//
//extension SharedStateStore: DependencyKey {
//    static let liveValue: SharedStateStore = SharedStateStore()
//}
//
//extension DependencyValues {
//
//    var sharedState: SharedStateStore {
//        get { self[SharedStateStore.self] }
//        set { self[SharedStateStore.self] = newValue }
//    }
//}

struct SharedState: Equatable {
    //    var multipeerConnectivityState: MultipeerConnectivityState?
    var connectedPeerInfos: [PeerInfo] = []
    var connectionCandidatePeerInfos: [PeerInfo] = []
    var isReadTextEnable = false {
        didSet {
            print("didSet isReadTextEnable: \(isReadTextEnable)")
            UserDefaults.standard.isReadTextEnable = isReadTextEnable
        }
    }
    var isReceiveMessageDisplayOnlyMode = false {
        didSet {
            UserDefaults.standard.isReceiveMessageDisplayOnlyMode = isReceiveMessageDisplayOnlyMode
        }
    }
    var isGuestReadTextEnable = false {
        didSet {
            UserDefaults.standard.isGuestReadTextEnable = isGuestReadTextEnable
        }
    }
    var userDisplayName = "" {
        didSet {
            UserDefaults.standard.userDisplayName = userDisplayName
            if !userDisplayName.isEmpty {
                MCManager.shared.changePeerDisplayName(displayName: userDisplayName)
            }
        }
    }

    init(
        connectedPeerInfos: [PeerInfo] = [],
        connectionCandidatePeerInfos: [PeerInfo] = [],
        isReadTextEnable: Bool,
        isReceiveMessageDisplayOnlyMode: Bool,
        isGuestReadTextEnable: Bool,
        userDisplayName: String
    ) {
        self.connectedPeerInfos = connectedPeerInfos
        self.connectionCandidatePeerInfos = connectionCandidatePeerInfos
        self.isReadTextEnable = isReadTextEnable
        self.isReceiveMessageDisplayOnlyMode = isReceiveMessageDisplayOnlyMode
        self.isGuestReadTextEnable = isGuestReadTextEnable
        self.userDisplayName = userDisplayName
    }

}

// Ref: https://github.com/pointfreeco/isowords/blob/2a0ab0da3651c16402b6f1b7e6b85c7ead3bf249/Sources/UserSettingsClient/UserSettingsClient.swift
struct SharedStateClient {
    public var get: @Sendable () -> SharedState
    public var set: @Sendable (SharedState) async -> Void
    public var stream: @Sendable () -> AsyncStream<SharedState>

    public subscript<Value>(dynamicMember keyPath: KeyPath<SharedState, Value>) -> Value {
        self.get()[keyPath: keyPath]
    }

    @_disfavoredOverload
    public subscript<Value>(
        dynamicMember keyPath: KeyPath<SharedState, Value>
    ) -> AsyncStream<Value> {
        // TODO: This should probably remove duplicates.
        self.stream().map { $0[keyPath: keyPath] }.eraseToStream()
    }

    public func modify(_ operation: (inout SharedState) -> Void) async {
        var sharedState = get()
        operation(&sharedState)
        await self.set(sharedState)
    }
}

extension SharedStateClient: DependencyKey {
    public static var liveValue: SharedStateClient {
        let initialSharedState = SharedState(
            isReadTextEnable: UserDefaults.standard.isReadTextEnable,
            isReceiveMessageDisplayOnlyMode: UserDefaults.standard.isReceiveMessageDisplayOnlyMode,
            isGuestReadTextEnable: UserDefaults.standard.isGuestReadTextEnable,
            userDisplayName: UserDefaults.standard.userDisplayName
        )
        let sharedState = LockIsolated(initialSharedState)
        let subject = PassthroughSubject<SharedState, Never>()
        return Self(
            get: {
                return sharedState.value
            },
            set: { updatedSharedState in
                sharedState.withValue {
                    $0 = updatedSharedState
                    subject.send(updatedSharedState)
                }
            },
            stream: {
                subject.values.eraseToStream()
            }
        )
    }


}

extension DependencyValues {
    var sharedState: SharedStateClient {
        get { self[SharedStateClient.self] }
        set { self[SharedStateClient.self] = newValue }
    }
}

public let userSettingsFileName = "user-settings"
