//
//  ChatListReducer.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/11/14.
//


import Foundation
import ComposableArchitecture
import SwiftUI

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

    var isOther: Bool {
        switch self {
        case .me: return false
        case .other: return true
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

struct ChatListReducer: Reducer {
    typealias State = ChatListReducer.ChatListState
    typealias Action = ChatListReducer.ChatListAction
    @Dependency(\.sharedState) var sharedState
    private var task: Task<Void, Never>?

    struct ChatListState: Equatable {
        var newMessage: String = ""
        fileprivate var messages: [MessageCreaterType] = []
        var scrollToRowId: String?
        var adjustedMessages: [MessageCreaterType] {
            if UserDefaults.standard.isReceiveMessageDisplayOnlyMode {
                return messages.filter(\.isOther)
            } else {
                return messages
            }
        }
        @BindingState public var sharedState: SharedState

        init(
            newMessage: String = "",
            messages: [MessageCreaterType] = [],
            scrollToRowId: String? = nil
        ) {
            @Dependency(\.sharedState) var sharedState

            self.newMessage = newMessage
            self.messages = messages
            self.scrollToRowId = scrollToRowId
            self.sharedState = sharedState.get()
        }
    }

    enum ChatListAction: BindableAction, Equatable {
        case textChanged(String)
        case didTapSendButton
        case willScrollToBottom
        case didTapMessageDeleteButton(messageItem: MessageItem)
        case readErrorMessage(messageItem: MessageItem)
        case didCompleteReadingErrorText(index: Int)
        case didCompleteReading(index: Int)
        case readMessage
        case didErrorReading(index: Int)
        case didScrollToBottom
        case binding(BindingAction<State>)
        case updateSharedState(SharedState)
        case didReceiveMessage(messageItem: MessageItem)

        enum AdvertiserInvitationAlertAction: Equatable {
            case didTapAdvertiserInvitationOkButton(info: AdvertiserInvitationInfo)
            case didTapAdvertiserInvitationCancelButton(info: AdvertiserInvitationInfo)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch(action) {
            case .textChanged(let text):
                state.newMessage = text
                return .none
            case .didTapSendButton:
                let message = state.newMessage.trimmed()
                state.messages.append(
                    .me(messageItem: .init(
                        message: message,
                        date: Date.now,
                        displayUserName: Device.marketingName ?? Device.name,
                        readingStatus: .willRead
                    ))
                )
                state.newMessage = ""
                MCManager.shared.sendMessage(text: message)
                if UserDefaults.standard.isReadTextEnable {
                    return .run { send in
                        await send(.readMessage)
                    }
                } else {
                    return updateMessageItem(
                        index: state.messages.count - 1,
                        readingStatus: .readCompleted,
                        state: &state)
                }
            case .willScrollToBottom:
                if let messageId = state.adjustedMessages
                    .first(where: { $0.messageItem.readingStatus.isReading })?.messageItem.id {
                    state.scrollToRowId = messageId
                } else {
                    state.scrollToRowId = state.adjustedMessages.last?.messageItem.id
                }
            case .didTapMessageDeleteButton(let messageItem):
                state.messages.removeAll(where: { $0.messageItem.id == messageItem.id })
                return .none
            case .readErrorMessage(let messageItem):
                return readErrorText(messageItem: messageItem, state: &state)
            case .didCompleteReadingErrorText(let index):
                return updateMessageItem(index: index, readingStatus: .readCompleted, state: &state)
            case .didCompleteReading(let index):
                return .concatenate(
                    updateMessageItem(index: index, readingStatus: .readCompleted, state: &state),
                    .send(.readMessage)
                )
            case .didErrorReading(let index):
                return updateMessageItem(index: index, readingStatus: .readCompleted, state: &state)
            case .readMessage:
                return readText(state: &state)
            case .didScrollToBottom:
                state.scrollToRowId = nil
            case .updateSharedState(let sharedState):
                if state.sharedState != sharedState {
                    state.sharedState = sharedState
                }
            case .binding(\.$sharedState):
                return .none
            case .binding: // ここはその他の`binding`が流れてくる(今回はなし)
                return .none
            case .didReceiveMessage(messageItem: let messageItem):
                state.messages.append(.other(messageItem: messageItem))
                let effect: Effect<ChatListReducer.Action> = {
                    if state.sharedState.isGuestReadTextEnable {
                        return .send(.readMessage)
                    } else {
                        return updateMessageItem(
                            index: state.messages.count - 1,
                            readingStatus: .readCompleted,
                            state: &state
                        )
                    }
                }()
                return .concatenate(
                    Effect<ChatListReducer.Action>.send(.willScrollToBottom),
                    effect
                )
            }
            return .none
        }
    }
}


private extension ChatListReducer {
    func readText(state: inout ChatListReducer.State) -> Effect<ChatListReducer.Action> {
        guard !state.messages.contains(where: { $0.messageItem.readingStatus == .reading }),
              let willReadMessageItem = state.messages.sorted(by: \.messageItem.date)
            .first(where: { $0.messageItem.readingStatus == .willRead }),
              let index = state.messages
            .firstIndex(where: { $0.messageItem.id == willReadMessageItem.messageItem.id }) else { return .none }
        let messageType = state.messages[index]
        let messageItem = messageType.messageItem
        let shouldRead = switch messageType {
        case .me:
            state.sharedState.isReadTextEnable
        case .other:
            state.sharedState.isGuestReadTextEnable
        }
        if shouldRead {
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
        } else {
            return updateMessageItem(index: index, readingStatus: .readCompleted, state: &state)
        }
    }

    func readErrorText(messageItem: MessageItem, state: inout ChatListReducer.State) -> Effect<ChatListReducer.Action> {
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

    func updateMessageItem(index: Int, readingStatus: ReadingStatus, state: inout ChatListReducer.State) -> Effect<ChatListReducer.Action> {
        if state.messages.count <= index { return .none }
        let messageType = state.messages[index]
        let messageItem = messageType.messageItem
        let newMessageItem = MessageItem(
            message: messageItem.message,
            date: messageItem.date,
            displayUserName: messageItem.displayUserName,
            readingStatus: readingStatus
        )
        withAnimation {
            if messageType.isMe {
                state.messages[index] = .me(messageItem: newMessageItem)
            } else {
                state.messages[index] = .other(messageItem: newMessageItem)
            }
        }
        return .none
    }
}

// Ref: https://zenn.dev/kalupas226/articles/87b1f7b245915c#%E5%95%8F%E9%A1%8C%E3%81%AE%E8%A7%A3%E6%B1%BA%E6%96%B9%E6%B3%95
extension ChatListReducer.ChatListState {
    mutating func update(messageItem: MessageItem) -> Effect<ChatListReducer.Action> {
        return .send(.didReceiveMessage(messageItem: messageItem))
    }
}
