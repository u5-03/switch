////
////  Reducer.swift
////  Switch
////
////  Created by Yugo Sugiyama on 2023/09/23.
////
//
//import Foundation
//import ComposableArchitecture
//import SwiftUI
//import MultipeerConnectivity
//


//struct Feature: Reducer {
//    typealias State = Feature.AppState
//    private var task: Task<Void, Never>?
//    @Dependency(\.multipeerConnectivityClient) var multipeerConnectivityClient
//
//    struct AppState: Equatable {
//        var isConfigPresented = false
//        var newMessage: String = ""
//        fileprivate var messages: [MessageCreaterType] = []
//        var mcState = MultipeerConnectivityState()
//        @PresentationState var advertiserInvitationAlertState: AlertState<ConfigAction.AdvertiserInvitationAlertAction>?
//        var isMcBrowserSheetPresented = false // 
//        var scrollToRowId: String?
//        var adjustedMessages: [MessageCreaterType] {
//            return []
////            if mcState.isReceiveMessageDisplayOnlyMode {
////                return messages.filter(\.isOther)
////            } else {
////                return messages
////            }
//        }
//
//        static func == (lhs: Feature.AppState, rhs: Feature.AppState) -> Bool {
//            return lhs.isConfigPresented == rhs.isConfigPresented &&
//            lhs.newMessage == rhs.newMessage &&
//            lhs.messages == rhs.messages &&
//            lhs.mcState == rhs.mcState &&
//            lhs.advertiserInvitationAlertState == rhs.advertiserInvitationAlertState &&
//            lhs.isMcBrowserSheetPresented == rhs.isMcBrowserSheetPresented
//        }
//    }
//
//    enum Action: Equatable {
//        case didTapConfigButton
//        case toggleConfigButtonPresented
//        case didTapSendButton
//        case didTapMessageDeleteButton(messageItem: MessageItem)
//        case readErrorMessage(messageItem: MessageItem)
//        
//        case textChanged(String)
//        case clearNewText
//
//        
//        case startMultipeerConnectivity

//        case configAction(action: ConfigAction)

//        case willScrollToBottom
//        case didScrollToBottom
//
//        case advertiserInvitationAlert(action: PresentationAction<ConfigAction.AdvertiserInvitationAlertAction>)
//    }
//
//    var body: some Reducer<Feature.AppState, Feature.Action> {
//        Reduce { state, action in
//            switch action {
//            case .didTapConfigButton:
//                state.isConfigPresented = true
//                return .none
//            case .toggleConfigButtonPresented:
//                state.isConfigPresented = false
//                return .none
//            case .didTapSendButton:
//                let message = state.newMessage.trimmed()
//                state.messages.append(
//                    .me(messageItem: .init(
//                        message: message,
//                        date: Date(),
//                        displayUserName: Device.marketingName ?? Device.name,
//                        readingStatus: .willRead
//                    ))
//                )
//                state.newMessage = ""
//                MCManager.shared.sendMessage(text: message)
////                if state.mcState.isReadTextEnable {
////                    return .run { send in
////                        await send(.readMessage)
////                    }
////                } else {
////                    return updateMessageItem(
////                        index: state.messages.count - 1,
////                        readingStatus: .readCompleted,
////                        state: &state)
////                }
//            case .didTapMessageDeleteButton(let messageItem):
//                state.messages.removeAll(where: { $0.messageItem.id == messageItem.id })
//                return .none
//            case .readErrorMessage(let messageItem):
//                return readErrorText(messageItem: messageItem, state: &state)
//            
//            case .textChanged(let text):
//                state.newMessage = text
//                return .none
//            case .clearNewText:
//                state.newMessage = ""
//                return .none
//            
//            
//            case .startMultipeerConnectivity:
//                return .none

//            case .willScrollToBottom:
//                if let messageId = state.adjustedMessages
//                    .first(where: { $0.messageItem.readingStatus.isReading })?.messageItem.id {
//                    state.scrollToRowId = messageId
//                } else {
//                    state.scrollToRowId = state.adjustedMessages.last?.messageItem.id
//                }
//            
//            case .advertiserInvitationAlert(let alertAction):
//                switch alertAction {
//                case .dismiss:
//                    state.advertiserInvitationAlertState = nil
//                case .presented(let action):
//                    switch action {
//                    case .didTapAdvertiserInvitationOkButton(let info):
//                        info.invitationHandler(true, MCManager.shared.mcSession)
//                    case .didTapAdvertiserInvitationCancelButton(let info):
//                        info.invitationHandler(false, MCManager.shared.mcSession)
//                    }
//                }
//                return .none
            
//            case .configAction(let action):
//                switch action {
//                case .didTapAdvertisingPeerButton:
//                    let isStartAdvertisingPeer = state.mcState.isStartAdvertisingPeer
//                    if state.mcState.isStartAdvertisingPeer {
//                        state.mcState.isStartAdvertisingPeer = false
//                    } else {
//                        state.mcState.isStartAdvertisingPeer = true
//                    }
//                    return .run { send in
//                        if isStartAdvertisingPeer {
//                            MCManager.shared.stopAdvertisingPeer()
//                        } else {
//                            MCManager.shared.startAdvertisingPeer()
//                        }
//                    }
//                case .switchHostMode:
//                    state.mcState.userMode = state.mcState.userMode == .host ? .guest : .host
//                    let isHostMode = state.mcState.userMode == .host
//                    if isHostMode {
//                        state.mcState.isStartAdvertisingPeer = false
//                    }
//                    return .run { send in
//                        if isHostMode {
//                            MCManager.shared.stopAdvertisingPeer()
//                        }
//                    }
//                case .didCloseBrowserView:
//                    state.mcState.browserViewPresentationState = nil
//                    return .none
////                case .advertiserInvitationAlert(let alertAction):
////                    switch alertAction {
////                    case .dismiss:
////                        state.advertiserInvitationAlertState = nil
////                    case .presented:
////                        print("Presented")
////                    }
////                    return .none
//                case .mcBrowserSheet(let action):
//                    return .none
//                    //                switch action {
//                    //                case .dismiss:
//                    //                    state.mcState.browserViewPresentationState = nil
//                    //                case .presented(let action):
//                    //                    state.mcState.browserViewPresentationState
//                    //                }
//                case .advertiserInvitationAlertAction(action: let action):
////                    switch action {
////                    case .didTapAdvertiserInvitationOkButton(let info):
////                        info.invitationHandler(true, MCManager.shared.mcSession)
////                    case .didTapAdvertiserInvitationCancelButton(let info):
////                        info.invitationHandler(false, MCManager.shared.mcSession)
////                    }
//                    return .none
//                case .toggleReadTextEnable:
////                    state.mcState.isReadTextEnable.toggle()
//                    break
//                case .toggleGuestReadTextEnable:
////                    state.mcState.isGuestReadTextEnable.toggle()
//                    break
//                case .toggleReceiveMessageDisplayOnlyMode:
////                    state.mcState.isReceiveMessageDisplayOnlyMode.toggle()
//                    break
//                case .didChangedUserDisplayNameText(let text):
//                    state.mcState.userDisplayName = text
//                }
//            }
//            return .none
//        }
//        .ifLet(\.$advertiserInvitationAlertState, action: /Feature.Action.advertiserInvitationAlert)
//    }
//}
