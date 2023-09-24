//
//  Reducer.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import MultipeerConnectivity

enum MessageCreaterType: Equatable, Identifiable, Hashable {
    var id: Self {
        return self
    }

    case me(messageItem: MessageItem)
    case other(messageItem: MessageItem)

    var messageItem: MessageItem {
        switch self {
        case .me(let messageItem): return messageItem
        case .other(let messageItem): return messageItem
        }
    }

    var isMe: Bool {
        switch self {
        case .me: return true
        case .other: return false
        }
    }
}

enum CancelID: Int {
  case multipeerConnectivity
}

struct MessageItem: Identifiable, Hashable {
    let id = UUID().uuidString
    let message: String
    let date: Date
    let displayUserName: String
    let readingStatus: ReadingStatus
}

struct AdvertiserInvitationInfo: Equatable {
    let peerId: MCPeerID
    let invitationHandler: ((Bool, MCSession?) -> Void)

    static func == (lhs: AdvertiserInvitationInfo, rhs: AdvertiserInvitationInfo) -> Bool {
        return lhs.peerId == rhs.peerId
    }
}

struct Feature: Reducer {
    typealias State = Feature.AppState
    private var task: Task<Void, Never>?
    @Dependency(\.multipeerConnectivityClient) var multipeerConnectivityClient

    struct AppState: Equatable {
        var isConfigPresented = false
        var newMessage: String = ""
        var messages: [MessageCreaterType] = []
        var mcState = MultipeerConnectivityState()
        @PresentationState var advertiserInvitationAlertState: AlertState<ConfigAction.AdvertiserInvitationAlertAction>?
        var isMcBrowserSheetPresented = false

        static func == (lhs: Feature.AppState, rhs: Feature.AppState) -> Bool {
            return lhs.isConfigPresented == rhs.isConfigPresented &&
            lhs.newMessage == rhs.newMessage &&
            lhs.messages == rhs.messages &&
            lhs.mcState == rhs.mcState &&
            lhs.advertiserInvitationAlertState == rhs.advertiserInvitationAlertState &&
            lhs.isMcBrowserSheetPresented == rhs.isMcBrowserSheetPresented
        }
    }

    enum Action: Equatable {
        case didTapConfigButton
        case toggleConfigButtonPresented
        case didTapSendButton
        case didTapMessageDeleteButton(messageItem: MessageItem)
        case readErrorMessage(messageItem: MessageItem)
        case readMessage
        case textChanged(String)
        case clearNewText
        case didCompleteReading(index: Int)
        case didCompleteReadingErrorText(index: Int)
        case didErrorReading(index: Int)
        case startMultipeerConnectivity
        case mcAction(action: MultipeerConnectivityDelegateAction)
        case configAction(action: ConfigAction)
        case task

        case advertiserInvitationAlert(action: PresentationAction<ConfigAction.AdvertiserInvitationAlertAction>)
//        case advertiserInvitationAlert(action: PresentationAction<ConfigAction.AdvertiserInvitationAlertAction>)
    }

    var body: some Reducer<Feature.AppState, Feature.Action> {
        Reduce { state, action in
            switch action {
            case .didTapConfigButton, .toggleConfigButtonPresented:
                state.isConfigPresented.toggle()
                return .none
            case .didTapSendButton:
                let message = state.newMessage.trimmed()
                state.messages.append(
                    .me(messageItem: .init(
                        message: message,
                        date: Date(),
                        displayUserName: Device.marketingName ?? Device.name,
                        readingStatus: .willRead
                    ))
                )
                state.newMessage = ""
                return .run { send in
                    MCManager.shared.sendMessage(text: message)
                    await send(.readMessage)
                }
            case .didTapMessageDeleteButton(let messageItem):
                state.messages.removeAll(where: { $0.messageItem.id == messageItem.id })
                return .none
            case .readErrorMessage(let messageItem):
                return readErrorText(messageItem: messageItem, state: &state)
            case .readMessage:
                return readText(state: &state)
            case .textChanged(let text):
                if !text.isEmpty || state.newMessage != text {
                    state.newMessage = text
                    print("Text: changed \(text)")
                }
                return .none
            case .clearNewText:
                state.newMessage = ""
                return .none
            case .didCompleteReading(let index):
                return .concatenate(
                    updateMessageItem(index: index, readingStatus: .readCompleted, state: &state),
                    .send(.readMessage)
                )
            case .didCompleteReadingErrorText(let index):
                return updateMessageItem(index: index, readingStatus: .readCompleted, state: &state)
            case .didErrorReading(let index):
                return updateMessageItem(index: index, readingStatus: .readCompleted, state: &state)
            case .startMultipeerConnectivity:
                return .none
            case .task:
                return .run { send in
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            await withTaskCancellation(id: CancelID.multipeerConnectivity, cancelInFlight: true) {
                                for await action in await multipeerConnectivityClient.delegate() {
                                    await send(.mcAction(action: action), animation: .default)
                                }
                            }
                        }
                    }
                }
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
                return .none
            case .mcAction(let action):
                switch action {
                case .sessionDidChanaged(_, _):
                    state.mcState.connectedPeerInfos = MCManager.shared.mcSession.connectedPeers
                        .map({ PeerInfo(peerId: $0) })
                case .sessionDidReceived(let data, let peerID):
                    guard let message = String(data: data, encoding: .utf8) else { return .none }
                    let messageItem = MessageItem(message: message, date: Date(), displayUserName: peerID.displayName, readingStatus: .willRead)
                    state.messages.append(.other(messageItem: messageItem))
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
                    state.mcState.connectionCandidatePeerInfos.append(.init(peerId: foundPeerId))
                case .browserLost(_, let lostPeerId):
                    state.mcState.connectionCandidatePeerInfos.removeAll(where: { $0.peerId == lostPeerId })
                }
                return .none
            case .configAction(let action):
                switch action {
                case .didTapAdvertisingPeerButton:
                    let isStartAdvertisingPeer = state.mcState.isStartAdvertisingPeer
                    if state.mcState.isStartAdvertisingPeer {
                        state.mcState.isStartAdvertisingPeer = false
                    } else {
                        state.mcState.isStartAdvertisingPeer = true
                    }
                    return .run { send in
                        if isStartAdvertisingPeer {
                            MCManager.shared.stopAdvertisingPeer()
                        } else {
                            MCManager.shared.startAdvertisingPeer()
                        }
                    }
                case .switchHostMode:
                    state.mcState.userMode = state.mcState.userMode == .host ? .guest : .host
                    let isHostMode = state.mcState.userMode == .host
                    if isHostMode {
                        state.mcState.isStartAdvertisingPeer = false
                    }
                    return .run { send in
                        if isHostMode {
                            MCManager.shared.stopAdvertisingPeer()
                        }
                    }
                case .didCloseBrowserView:
                    state.mcState.browserViewPresentationState = nil
                    return .none
//                case .advertiserInvitationAlert(let alertAction):
//                    switch alertAction {
//                    case .dismiss:
//                        state.advertiserInvitationAlertState = nil
//                    case .presented:
//                        print("Presented")
//                    }
//                    return .none
                case .mcBrowserSheet(let action):
                    return .none
                    //                switch action {
                    //                case .dismiss:
                    //                    state.mcState.browserViewPresentationState = nil
                    //                case .presented(let action):
                    //                    state.mcState.browserViewPresentationState
                    //                }
                case .advertiserInvitationAlertAction(action: let action):
//                    switch action {
//                    case .didTapAdvertiserInvitationOkButton(let info):
//                        info.invitationHandler(true, MCManager.shared.mcSession)
//                    case .didTapAdvertiserInvitationCancelButton(let info):
//                        info.invitationHandler(false, MCManager.shared.mcSession)
//                    }
                    return .none
                case .setSheet(isPresented: let isPresented):
                    state.isMcBrowserSheetPresented = isPresented
                    return .none
                }
            }
        }
        .ifLet(\.$advertiserInvitationAlertState, action: /Feature.Action.advertiserInvitationAlert)
    }
}

private extension Reducer {
    func readText(state: inout Feature.AppState) -> Effect<Feature.Action> {
        guard !state.messages.contains(where: { $0.messageItem.readingStatus == .reading }),
              let willReadMessageItem = state.messages.sorted(by: \.messageItem.date)
            .first(where: { $0.messageItem.readingStatus == .willRead }),
              let index = state.messages.firstIndex(where: { $0.messageItem.id == willReadMessageItem.messageItem.id }) else { return .none }
        let messageItem = state.messages[index].messageItem
        return .concatenate(
            updateMessageItem(index: index, readingStatus: .reading, state: &state),
            .run { send in
                do {
                    try await TextReaderManager.shared.read(text: messageItem.message)
                    return await send(.didCompleteReading(index: index))
                } catch {
                    return await send(.didErrorReading(index: index))
                }
            }
        )
    }

    func readErrorText(messageItem: MessageItem, state: inout Feature.AppState) -> Effect<Feature.Action> {
        guard let index = state.messages.firstIndex(where: { $0.messageItem.id == messageItem.id }) else { return .none }
        return .concatenate(
            updateMessageItem(index: index, readingStatus: .reading, state: &state),
            .run { send in
                do {
                    try await TextReaderManager.shared.read(text: messageItem.message)
                    return await send(.didCompleteReadingErrorText(index: index))
                } catch {
                    return await send(.didErrorReading(index: index))
                }
            }
        )
    }

    func updateMessageItem(index: Int, readingStatus: ReadingStatus, state: inout Feature.AppState) -> Effect<Feature.Action> {
        if state.messages.count <= index { return .none }
        let messageItem = state.messages[index].messageItem
        let newMessageItem = MessageItem(
            message: messageItem.message,
            date: messageItem.date,
            displayUserName: messageItem.displayUserName,
            readingStatus: readingStatus
        )
        withAnimation {
            state.messages[index] = .me(messageItem: newMessageItem)
        }
        return .none
    }
}
