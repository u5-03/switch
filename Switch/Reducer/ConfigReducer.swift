//
//  ConfigReducer.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/11/10.
//

import Foundation
import ComposableArchitecture
import MultipeerConnectivity

struct AdvertiserInvitationInfo: Equatable {
    let peerId: MCPeerID
    let invitationHandler: ((Bool, MCSession?) -> Void)

    static func == (lhs: AdvertiserInvitationInfo, rhs: AdvertiserInvitationInfo) -> Bool {
        return lhs.peerId == rhs.peerId
    }
}

struct ConfigReducer: Reducer {
    typealias State = ConfigReducer.ConfigState
    typealias Action = ConfigReducer.ConfigAction
    @Dependency(\.sharedState) var sharedState

    struct ConfigState: Equatable {
        var userMode: MCMode = .host
        var isStartAdvertisingPeer = false
        var isMcBrowserSheetPresented = false
        var multipeerConnectivityState: ChatListReducer.ChatListState = .init()
        @BindingState public var sharedState: SharedState

        init(
            userMode: MCMode = .host,
            isStartAdvertisingPeer: Bool = false,
            isMcBrowserSheetPresented: Bool = false,
            isGuestReadTextEnable: Bool = false,
            userDisplayName: String = ""
        ) {
            @Dependency(\.sharedState) var sharedState
            self.userMode = userMode
            self.isStartAdvertisingPeer = isStartAdvertisingPeer
            self.isMcBrowserSheetPresented = isMcBrowserSheetPresented
            self.sharedState = sharedState.get()
        }

        static func == (lhs: State, rhs: State) -> Bool {
            return lhs.userMode == rhs.userMode &&
            lhs.isStartAdvertisingPeer == rhs.isStartAdvertisingPeer &&
            lhs.isMcBrowserSheetPresented == rhs.isMcBrowserSheetPresented &&
            lhs.sharedState == rhs.sharedState
        }
    }

    enum ConfigAction: BindableAction, Equatable {
        case switchMcBrowserSheet(isPresented: Bool)
        case switchHostMode
        case toggleReadTextEnable
        case toggleGuestReadTextEnable
        case toggleReceiveMessageDisplayOnlyMode
        case didChangedUserDisplayNameText(name: String)
        case didTapAdvertisingPeerButton
        case didChangedSession
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch(action) {
            case .switchMcBrowserSheet(let isPresented):
                state.isMcBrowserSheetPresented = isPresented
            case .switchHostMode:
                state.userMode = state.userMode == .host ? .guest : .host
                let isHostMode = state.userMode == .host
                if isHostMode {
                    state.isStartAdvertisingPeer = false
                }
                return .run { send in
                    if isHostMode {
                        MCManager.shared.stopAdvertisingPeer()
                    }
                }
            case .toggleReadTextEnable:
                state.sharedState.isReadTextEnable = !state.sharedState.isReadTextEnable
                return .none
            case .toggleGuestReadTextEnable:
                state.sharedState.isGuestReadTextEnable = !state.sharedState.isGuestReadTextEnable
            case .toggleReceiveMessageDisplayOnlyMode:
                state.sharedState.isReceiveMessageDisplayOnlyMode.toggle()
                return .none
            case .didChangedUserDisplayNameText(let userName):
                state.sharedState.userDisplayName = userName
            case .didChangedSession:
                state.sharedState.connectedPeerInfos = MCManager.shared.mcSession.connectedPeers
                                        .map({ PeerInfo(peerId: $0) })
            case .didTapAdvertisingPeerButton:
                let isStartAdvertisingPeer = state.isStartAdvertisingPeer
                if state.isStartAdvertisingPeer {
                    state.isStartAdvertisingPeer = false
                } else {
                    state.isStartAdvertisingPeer = true
                }
                return .run { send in
                    if isStartAdvertisingPeer {
                        MCManager.shared.stopAdvertisingPeer()
                    } else {
                        MCManager.shared.startAdvertisingPeer()
                    }
                }
            case .binding(\.$sharedState):  // ここにtextの変更が流れてくる
                return .none
            case .binding: // ここはその他の`binding`が流れてくる(今回はなし)
                return .none
            }
            return .none
        }
        .onChange(of: \.sharedState) { _, sharedState in
            Reduce { _, _ in
                enum CancelID { case saveDebounce }

                return .run { _ in
                    await self.sharedState.set(sharedState)
                }
            }
        }
    }
}


extension ConfigReducer.ConfigState {
    func update() -> Effect<ConfigReducer.ConfigAction> {
        return .send(.didChangedSession)
    }
}
