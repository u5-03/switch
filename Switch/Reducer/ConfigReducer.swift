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
        @PresentationState var advertiserInvitationAlertState: AlertState<ConfigAction.AdvertiserInvitationAlertAction>?
        @BindingState public var sharedState: SharedState {
            didSet {
                print("ConfigReducer:BindingState Set SharedState: \(sharedState.isReadTextEnable)")
            }
        }

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
            self.advertiserInvitationAlertState = nil
            self.sharedState = sharedState.get()
        }

        static func == (lhs: State, rhs: State) -> Bool {
            return lhs.userMode == rhs.userMode &&
            lhs.isStartAdvertisingPeer == rhs.isStartAdvertisingPeer &&
            lhs.isMcBrowserSheetPresented == rhs.isMcBrowserSheetPresented &&
            lhs.advertiserInvitationAlertState == rhs.advertiserInvitationAlertState &&
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
        case advertiserInvitationAlert(action: PresentationAction<ConfigAction.AdvertiserInvitationAlertAction>)
        case binding(BindingAction<State>)

        enum AdvertiserInvitationAlertAction: Equatable {
            case didTapAdvertiserInvitationOkButton(info: AdvertiserInvitationInfo)
            case didTapAdvertiserInvitationCancelButton(info: AdvertiserInvitationInfo)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch(action) {
            case .switchMcBrowserSheet(let isPresented):
                state.isMcBrowserSheetPresented = isPresented
            case .advertiserInvitationAlert(let alertAction):
                switch alertAction {
                case .dismiss:
                    state.advertiserInvitationAlertState = nil
                case .presented(let action):
                    switch action {
                    case .didTapAdvertiserInvitationOkButton(let info):
                        info.invitationHandler(true, MCManager.shared.mcSession)
                    case .didTapAdvertiserInvitationCancelButton(let info):
                        info.invitationHandler(false, MCManager.shared.mcSession)
                    }
                }
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
                //                    state.sharedState.isReadTextEnable.toggle()
                //                return .run { send in
                //                    await sharedState.
                //                }
                print("toggleReadTextEnable Reducer")
                state.sharedState.isReadTextEnable = !state.sharedState.isReadTextEnable
                return .none
            case .toggleGuestReadTextEnable:
                state.sharedState.isGuestReadTextEnable = !state.sharedState.isGuestReadTextEnable
            case .toggleReceiveMessageDisplayOnlyMode:
                state.sharedState.isReceiveMessageDisplayOnlyMode.toggle()
                return .none
                //                return .run { send in
                //                    await sharedState.set(.toggleReceiveMessageDisplayOnlyMode)
                //                }
            case .didChangedUserDisplayNameText(let userName):
                state.sharedState.userDisplayName = userName
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
                print("変更:", state)
                return .none
            case .binding: // ここはその他の`binding`が流れてくる(今回はなし)
                return .none
            }
            return .none
        }
        .ifLet(\.$advertiserInvitationAlertState, action: /ConfigReducer.Action.advertiserInvitationAlert)
        .onChange(of: \.sharedState) { _, sharedState in
            Reduce { _, _ in
                enum CancelID { case saveDebounce }

                return .run { _ in
                    print("ConfigReducer: SharedState Change of \(sharedState)")
                    await self.sharedState.set(sharedState)
                }
//                    .debounce(id: CancelID.saveDebounce, for: .seconds(0.5), scheduler: self.mainQueue)
            }
        }
    }
}

