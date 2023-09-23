//
//  Reducer.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import Foundation
import ComposableArchitecture
import SwiftUI

struct Feature: Reducer {
    typealias State = AppState

    struct AppState: Equatable {
        var isConfigPresented = false
        var newMessage: String = ""
        var messages: [MessageItem] = []
    }

    enum Action: Equatable {
        case toggleConfigurePresenterd
        case addMessage(text: String)
        case deleteMessage(messageItem: MessageItem)
        case updateMessage(index: Int, readingStatus: ReadingStatus)
        case readErrorMessage(messageItem: MessageItem)
        case readMessage
        case textChanged(String)
        case clearNewText
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .toggleConfigurePresenterd:
            state.isConfigPresented.toggle()
            return .none
        case .addMessage(let text):
            state.messages.append(
                .init(
                    message: text.trimmed(),
                    date: Date(),
                    readingStatus: .willRead
                )
            )

            state.newMessage = ""
            return .run { send in
                await send(.readMessage)
            }
        case .deleteMessage(let messageItem):
            state.messages.removeAll(where: { $0.id == messageItem.id })
            return .none
        case .updateMessage(let index, let readingStatus):
            if state.messages.count <= index { return .none }
            let messageItem = state.messages[index]
            let newMessageItem = MessageItem(
                message: messageItem.message,
                date: messageItem.date,
                readingStatus: readingStatus
            )
            withAnimation {
                state.messages[index] = newMessageItem
            }
            return .none
        case .readErrorMessage(let messageItem):
            guard let index = state.messages.firstIndex(where: { $0.id == messageItem.id }) else { return .none }
            return .run { send in
                await send(.updateMessage(index: index, readingStatus: .reading))
                do {
                    try await TextReaderManager.shared.read(text: messageItem.message)
                    await send(.updateMessage(index: index, readingStatus: .readCompleted))
                } catch {
                    await send(.updateMessage(index: index, readingStatus: .readingError))
                }
            }
        case .readMessage:
            guard !state.messages.contains(where: { $0.readingStatus == .reading }),
                  let willReadMessageItem = state.messages.sorted(by: \.date)
                .first(where: { $0.readingStatus == .willRead }),
                  let index = state.messages.firstIndex(where: { $0.id == willReadMessageItem.id }) else { return .none }
            return .run { send in
                await send(.updateMessage(index: index, readingStatus: .reading))
                do {
                    try await TextReaderManager.shared.read(text: willReadMessageItem.message)
                    await send(.updateMessage(index: index, readingStatus: .readCompleted))
                    await send(.readMessage)
                } catch {
                    await send(.updateMessage(index: index, readingStatus: .readingError))
                }
            }
        case .textChanged(let text):
            state.newMessage = text
            return .none
        case .clearNewText:
            state.newMessage = ""
            return .none
        }
    }
}
