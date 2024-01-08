//
//  RootTabReducer.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/11/05.
//

import Foundation
import ComposableArchitecture

enum RootTabKind: String {
    case chatList
    case config

    var displayText: String {
        switch self {
        case .chatList: return "チャット"
        case .config: return "設定"
        }
    }
}

struct RootTabReducer: Reducer {
    typealias State = RootTabReducer.RootTabState
    typealias Action = RootTabReducer.RootTabAction
    @Dependency(\.multipeerConnectivityClient) var multipeerConnectivityClient

    struct RootTabState: Equatable {
        var selectedTab = RootTabKind.chatList.rawValue
        var chatListState: ChatListReducer.ChatListState = .init()
        var configState: ConfigReducer.ConfigState = .init()

        @PresentationState var advertiserInvitationAlertState: AlertState<Action.AdvertiserInvitationAlertAction>?
    }

    enum RootTabAction {
        case didChangedTab(tab: String)
        case chatListAction(ChatListReducer.Action)
        case configAction(ConfigReducer.Action)
        case multipeerConnectivityAction(MultipeerConnectivityDelegateAction)
        case task

        case advertiserInvitationAlert(action: PresentationAction<Action.AdvertiserInvitationAlertAction>)

        enum AdvertiserInvitationAlertAction: Equatable {
            case didTapAdvertiserInvitationOkButton(info: AdvertiserInvitationInfo)
            case didTapAdvertiserInvitationCancelButton(info: AdvertiserInvitationInfo)
        }
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.configState, action: /RootTabAction.configAction) {
          ConfigReducer()
        }
        Scope(state: \.chatListState, action: /RootTabAction.chatListAction) {
          ChatListReducer()
        }
        Reduce { state, action in
            switch(action) {
            case .didChangedTab(let tab):
                state.selectedTab = tab
                return .none
            case .chatListAction:
                return .none
            case .configAction:
                return .none
            case .task:
                print("SharedStateStream task init")
                return .run { send in
                    await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            await withTaskCancellation(id: CancelID.multipeerConnectivity, cancelInFlight: true) {
                                for await action in await multipeerConnectivityClient.delegate() {
                                    await send(.multipeerConnectivityAction(action), animation: .default)
                                }
                            }
                        }
                    }
                }
            case .multipeerConnectivityAction(let action):
                switch action {
                case .sessionDidChanaged(_, _):
                    return state.configState.update()
                        .map(RootTabAction.configAction)
                case .sessionDidReceived(let data, let peerID):
                    guard let message = String(data: data, encoding: .utf8) else { return .none }
                    let messageItem = MessageItem(message: message, date: Date(), displayUserName: peerID.displayName, readingStatus: .willRead)
                    return state.chatListState
                        .update(messageItem: messageItem)
                        .map(RootTabAction.chatListAction)
                case .advertiserDidReceiveInvitationFromPeer(let peerID, _, let invitationHandler):
                    let info = AdvertiserInvitationInfo(peerId: peerID, invitationHandler: invitationHandler)
                    state.advertiserInvitationAlertState = .init(
                        title: .init("ホストから招待が届きました"),
                        message: .init("ホストからの招待を承認しますか？"),
                        primaryButton: .cancel(
                            .init("キャンセル"),
                            action: .send(.didTapAdvertiserInvitationCancelButton(info: info))
                        ),
                        secondaryButton: .default(
                            .init("承認"),
                            action: .send(.didTapAdvertiserInvitationOkButton(info: info))
                        )
                    )
                case .browserFound(_, let foundPeerId, _):
                    // カスタムでMultipeerConnectivityのデバイス接続画面を実装する時に利用する
//                    state.sharedState.connectionCandidatePeerInfos.append(.init(peerId: foundPeerId))
                    break
                case .browserLost(_, let lostPeerId):
                    //                    state.mcState.connectionCandidatePeerInfos.removeAll(where: { $0.peerId == lostPeerId })
                    break
                }
            case .advertiserInvitationAlert(action: let alertAction):
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
            }
            return .none
        }
        .ifLet(\.$advertiserInvitationAlertState, action: /RootTabAction.advertiserInvitationAlert)
    }
}
