//
//  ChatBubbleView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/11.
//

import SwiftUI

// Ref: https://qiita.com/yuppejp/items/92429a0fc8440f9da487
private struct BalloonShapeView: View {
    var cornerRadius: Double
    var color: Color
    var mirrored = false

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let tailSize = CGSize(
                    width: cornerRadius,
                    height: cornerRadius)
                let shapeRect = CGRect(
                    x: 0,
                    y: 0,
                    width: geometry.size.width,
                    height: geometry.size.height)

                // 時計まわりに描いていく

                // 左上角丸
                path.addArc(
                    center: CGPoint(
                        x: shapeRect.minX + cornerRadius,
                        y: shapeRect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 279), clockwise: false)

                // 右上角丸
                path.addArc(
                    center: CGPoint(
                        x: shapeRect.maxX - cornerRadius - tailSize.width,
                        y: shapeRect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 270),
                    endAngle: Angle(degrees: 270 + 45), clockwise: false)

                // しっぽ上部
                path.addQuadCurve(
                    to: CGPoint(
                        x: shapeRect.maxX,
                        y: shapeRect.minY),
                    control: CGPoint(
                        x: shapeRect.maxX - (tailSize.width / 2),
                        y: shapeRect.minY))

                // しっぽ下部
                path.addQuadCurve(
                    to: CGPoint(
                        x: shapeRect.maxX - tailSize.width,
                        y: shapeRect.minY + (cornerRadius / 2) + tailSize.height),
                    control: CGPoint(
                        x: shapeRect.maxX - (tailSize.width / 2),
                        y: shapeRect.minY))

                // 右下角丸
                path.addArc(
                    center: CGPoint(
                        x: shapeRect.maxX - cornerRadius - tailSize.width,
                        y: shapeRect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90), clockwise: false)

                // 左下角丸
                path.addArc(
                    center: CGPoint(
                        x: shapeRect.minX + cornerRadius,
                        y: shapeRect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180), clockwise: false)
            }
            .fill(self.color)
//            .rotation3DEffect(.degrees(mirrored ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
    }
}

struct ChatBubbleView: View {
    let type: MessageCreaterType
    let mirrored: Bool
    let cornerRadius = 8.0
    let horizontalSpacingMargin: CGFloat = 12
    let iconLength = CGFloat(12)

    @ViewBuilder
    var statusIconView: some View {
        switch type.messageItem.readingStatus {
        case .reading:
            Image(systemName: "ellipsis")
                .symbolEffect(.variableColor.cumulative, options: .speed(10))
            // Ref: https://www.hackingwithswift.com/quick-start/swiftui/how-to-animate-sf-symbols
        case .readCompleted:
            Image(systemName: "checkmark")
                .foregroundStyle(type.messageItem.readingStatus.color)
        case .willRead:
            Image(systemName: "trash.fill")
                .foregroundStyle(type.messageItem.readingStatus.color)
        case .readingError:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(type.messageItem.readingStatus.color)
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(type.messageItem.message)
                .padding(.leading, horizontalSpacingMargin + (mirrored ? cornerRadius / 2 : 0))
                .padding(.trailing, horizontalSpacingMargin + (!mirrored ? cornerRadius / 2 : 0))
                .padding(.vertical, 4)
                .background(BalloonShapeView(
                    cornerRadius: cornerRadius,
                    color: type.messageItem.readingStatus.color,
                    mirrored: !type.isMe)
                )
            statusIconView
                .frame(width: iconLength, height: iconLength)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        ChatBubbleView(
            type: .me(messageItem: .init(
                message: "willRead " + .random,
                date: Date(),
                displayUserName: "DisplayName",
                readingStatus: .willRead
            )),
            mirrored: true
        )
        ChatBubbleView(
            type: .me(messageItem: .init(
                message: "reading " + .random,
                date: Date(),
                displayUserName: "DisplayName",
                readingStatus: .reading
            )),
            mirrored: true
        )
        ChatBubbleView(
            type: .me(messageItem: .init(
                message: "readCompleted " + .random,
                date: Date(),
                displayUserName: "DisplayName",
                readingStatus: .readCompleted
            )),
            mirrored: true
        )
        ChatBubbleView(
            type: .other(messageItem: .init(
                message: "readingError " + .random,
                date: Date(),
                displayUserName: "OtherDisplayName",
                readingStatus: .readingError
            )),
            mirrored: false
        )
    }
}
