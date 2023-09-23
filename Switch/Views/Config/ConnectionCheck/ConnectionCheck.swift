//
//  ConnectionCheck.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import SwiftUI

struct ConnectionCheck: View {
    var body: some View {
        Form {
            Section {
                ForEach(MCManager.shared.connectedDevices) { device in
                    Text(device.deviceName)
                }
            } header: {
                HStack(spacing: 2) {
                    Text("デバイスを探しています")
                    Image(systemName: "ellipsis")
                        .symbolEffect(.variableColor.cumulative, options: .speed(10))
                    Spacer()
                }
            }

        }
        .onAppear {
            MCManager.shared.startAdvertisingPeer()
        }
    }
}

#Preview {
    ConnectionCheck()
}
