//
//  ChartListState.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/18.
//

import Foundation
import Observation
import SwiftUI

struct MessageItem: Identifiable, Hashable {
    let id = UUID().uuidString
    let message: String
    let date: Date
    let readingStatus: ReadingStatus
}

@MainActor
@Observable
final class ChartListState {
    var newMessage: String = ""
    private(set) var messages: [MessageItem] = []
    let listID = UUID()

    func addMessage(text: String) {
        messages.append(
            .init(
                message: text.trimmed(),
                date: Date(),
                readingStatus: .willRead
            )
        )
        newMessage = ""
        Task {
            await readWillReadText()
        }
    }

    func deleteMessage(messageItem: MessageItem) {
        withAnimation {
            messages.removeAll(where: { $0.id == messageItem.id })
        }
    }

    func readErrorText(messageItem: MessageItem) async {
        guard let index = messages.firstIndex(where: { $0.id == messageItem.id }) else { return }
        updateMessageItemStatus(index: index, readingStatus: .reading)
        do {
            try await TextReaderManager.shared.read(text: messageItem.message)
            updateMessageItemStatus(index: index, readingStatus: .readCompleted)
        } catch {
            updateMessageItemStatus(index: index, readingStatus: .readingError)
        }
    }
    
    private func readWillReadText() async {
        guard !messages.contains(where: { $0.readingStatus == .reading }),
              let willReadMessageItem = messages.sorted(by: \.date)
            .first(where: { $0.readingStatus == .willRead }),
              let index = messages.firstIndex(where: { $0.id == willReadMessageItem.id }) else { return }
        updateMessageItemStatus(index: index, readingStatus: .reading)
        do {
            try await TextReaderManager.shared.read(text: willReadMessageItem.message)
            updateMessageItemStatus(index: index, readingStatus: .readCompleted)
            await readWillReadText()
        } catch {
            updateMessageItemStatus(index: index, readingStatus: .readingError)
        }
    }

    private func updateMessageItemStatus(index: Int, readingStatus: ReadingStatus) {
        if messages.count <= index { return }
        let messageItem = messages[index]
        let newMessageItem = MessageItem(
            message: messageItem.message,
            date: messageItem.date,
            readingStatus: readingStatus
        )
        withAnimation {
            messages[index] = newMessageItem
        }
    }
}

