//
//  BalloonShapeView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/26.
//

import SwiftUI

// Ref: https://qiita.com/yuppejp/items/92429a0fc8440f9da487
struct BalloonShapeView: View {
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
            .fill(color)
            .rotation3DEffect(.degrees(mirrored ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
    }
}
