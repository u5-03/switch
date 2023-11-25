//
//  ChatBubbleView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/11.
//

import SwiftUI

enum ChatItemAction {
    case delete(messageItem: MessageItem)
    case retry(messageItem: MessageItem)
}

struct ChatBubbleView: View {
    let type: MessageCreaterType
    let cornerRadius = 8.0
    let horizontalSpacingMargin: CGFloat = 8
    let iconLength = CGFloat(12)
    let isReceiveMessageDisplayOnlyMode: Bool
    private var isMe: Bool { return type.isMe }
    let itemAction: (ChatItemAction) -> Void

    var bubbleTextColor: Color {
        if isMe {
            return .white
        } else {
            return type.messageItem.displayUserName.generatdBrightColor.appropriateTextColor
        }
    }

    var bubbleViewBackgroundColor: Color {
        if isMe {
            return Contants.themeColor
        } else {
            return type.messageItem.displayUserName.generatdBrightColor
                .opacity(0.8)
        }
    }

    @ViewBuilder
    private var statusIconView: some View {
        switch type.messageItem.readingStatus {
        case .reading:
            Image(systemName: "ellipsis")
                .resizable()
                .scaledToFit()
                .symbolEffect(.variableColor.cumulative, options: .speed(10))
            // Ref: https://www.hackingwithswift.com/quick-start/swiftui/how-to-animate-sf-symbols
        case .readCompleted:
            Image(systemName: "checkmark")
                .resizable()
                .scaledToFit()
                .foregroundStyle(type.messageItem.readingStatus.color)
        case .willRead:
            Image(systemName: "trash.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(type.messageItem.readingStatus.color)
        case .readingError:
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(type.messageItem.readingStatus.color)
        }
    }

    private func messageSideView(isMe: Bool) -> some View {
        VStack(alignment: .leading) {
            Text(type.messageItem.date.asString(withFormat: .timeHourNoZero))
                .font(.system(size: 10))
            statusIconView
                .frame(width: iconLength, height: iconLength)
                .padding(.leading, 4)
        }
        .clipped()
    }

    var body: some View {
        VStack(alignment: isMe ? .trailing : .leading) {
            HStack(alignment: .bottom, spacing: 4) {
                if isMe {
                    Spacer()
                    messageSideView(isMe: false)
                }
                Text(type.messageItem.message)
                    .font(isReceiveMessageDisplayOnlyMode ? .largeTitle : .body)
                    .padding(.leading, horizontalSpacingMargin + (!isMe ? cornerRadius : 0))
                    .padding(.trailing, horizontalSpacingMargin + (isMe ? cornerRadius : 0))
                    .padding(.vertical, 4)
                    .foregroundColor(bubbleTextColor)
                    .background(
                        BalloonShapeView(
                        cornerRadius: cornerRadius,
                        color: bubbleViewBackgroundColor,
                        mirrored: !isMe)
                    )
                    .onTapGesture {
                        Task {
                            switch type.messageItem.readingStatus {
                            case .readingError:
                                itemAction(.retry(messageItem: type.messageItem))
                            case .willRead:
                                itemAction(.delete(messageItem: type.messageItem))
                            default:
                                break
                            }
                        }
                    }
                    .contextMenu {
                        Button(action: {
                            PasteBoard.copy(text: type.messageItem.message)
                        }) {
                            Text(String(localized: "Menu.copyMessage", defaultValue: "メッセージをコピーする"))
                            Image(systemName: "clipboard.fill")
                        }
                        Button(action: {
                            PasteBoard.copy(text: type.messageItem.message)
                        }) {
                            Text(String(localized: "Menu.copyDisplayName", defaultValue: "表示名をコピーする"))
                            Image(systemName: "clipboard.fill")
                        }

                        Button(action: {
                            itemAction(.delete(messageItem: type.messageItem))
                        }) {
                            Label(String(localized: "Menu.delete", defaultValue: "削除する"), systemImage: "trash.fill")
                        }
                    }
                if !isMe {
                    messageSideView(isMe: true)
                    Spacer()
                }
            }
            if !isMe {
                Text("by \(type.messageItem.displayUserName)")
                    .font(.system(size: 13))
                    .padding(.leading, 8)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ChatBubbleView(
            type: .me(messageItem: .init(
                message: String(localized: "ReadingStatus.willRead", defaultValue: "willRead ") + .random(range: 0...20),
                date: Date(),
                displayUserName: .random(range: 0...10),
                readingStatus: .willRead
            )),
            isReceiveMessageDisplayOnlyMode : true) { _ in }
        ChatBubbleView(
            type: .other(messageItem: .init(
                message: String(localized: "ReadingStatus.reading", defaultValue: "reading ") + .random(range: 0...20),
                date: Date(),
                displayUserName: .random(range: 0...10),
                readingStatus: .reading
            )),
            isReceiveMessageDisplayOnlyMode : true) { _ in }
        ChatBubbleView(
            type: .other(messageItem: .init(
                message: String(localized: "ReadingStatus.readCompleted", defaultValue: "readCompleted ") + .random(range: 0...20),
                date: Date(),
                displayUserName: String(localized: "DisplayName", defaultValue: "DisplayName"),
                readingStatus: .readCompleted
            )),
            isReceiveMessageDisplayOnlyMode : false) { _ in }
        ChatBubbleView(
            type: .other(messageItem: .init(
                message: String(localized: "ReadingStatus.readingError", defaultValue: "readingError ") + .random(range: 0...20),
                date: Date(),
                displayUserName: String(localized: "DisplayName", defaultValue: "DisplayName"),
                readingStatus: .readingError
            )),
            isReceiveMessageDisplayOnlyMode : false) { _ in }
    }
}
