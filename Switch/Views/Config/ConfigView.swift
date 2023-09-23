//
//  ConfigView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import SwiftUI

enum NavigationType {
    case connectionCheck
}

struct ConfigView: View {
    @State private var isSenderEnable = true
    @State private var isBrowserViewPresented = false
    private let myPeerID = MCManager.shared.peerID
    private let session = MCManager.shared.mcSession
    private let sessionType = MCManager.shared.serviceType

    var mcMode: MCMode {
        return isSenderEnable ? .sender : .receiver
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("接続モード") {
                    Toggle(mcMode.displayName, isOn: $isSenderEnable)
                    if mcMode == .sender {
                        Button(action: {
                            isBrowserViewPresented.toggle()
                        }, label: {
                            Text("受信デバイスを探す")
                        })
                        .buttonStyle(BorderlessButtonStyle())
                    } else {
                        NavigationLink {
                            ConnectionCheck()
                        } label: {
                            Text("接続確認")
                        }
                    }
                }
                if !MCManager.shared.connectedDevices.isEmpty {
                    Section("接続済みデバイス") {
                        ForEach(MCManager.shared.connectedDevices) { device in
                            Text(device.deviceName)
                        }
                    }
                }
                Section("情報") {
                    LabeledContent("デバイス情報") {
                        Text(Device.marketingName ?? Device.name)
                    }
                }
            }
            .fullScreenCover(isPresented: $isBrowserViewPresented, content: {
                NavigationStack {
                    MCBrowserViewControllerWrapper(serviceType: sessionType, peerID: myPeerID, session: session)
                        .navigationTitle("受信デバイスを探す")
                        .navigationBarTitleDisplayMode(.inline)
                }
            })
            .navigationDestination(for: NavigationType.self) { number in

            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    ConfigView()
}
