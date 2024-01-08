//
//  ConfigView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import SwiftUI
import ComposableArchitecture

enum NavigationType {
    case connectionCheck
}

struct ConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.sharedState) var sharedState
    private let myPeerID = MCManager.shared.peerID
    private let session = MCManager.shared.mcSession
    private let sessionType = MCManager.shared.serviceType

    let configStore: StoreOf<ConfigReducer>

    var connectionSectionView: some View {
        WithViewStore(configStore, observe: { $0 }) { viewStore in
            Section("接続モード") {
                Toggle(isOn: viewStore.binding(get: { state in
                    state.userMode == .host
                }, send: { value in
                    ConfigReducer.Action.switchHostMode
                })) {
                    Text(viewStore.userMode.displayName)
                }
                if viewStore.userMode == .host {
                    Button(action: {
                        viewStore.send(.switchMcBrowserSheet(isPresented: true))
                    }, label: {
                        Text("ゲストデバイスを探す")
                    })
                    .buttonStyle(BorderlessButtonStyle())
                } else {
                    HStack {
                        Button(action: {
                            viewStore.send(.didTapAdvertisingPeerButton)
                        }, label: {
                            Text(viewStore.isStartAdvertisingPeer ? "検索を停止する" : "ホストを探す")
                        })
                        .buttonStyle(BorderlessButtonStyle())
                        Spacer()
                        if viewStore.isStartAdvertisingPeer {
                            HStack(spacing: 2) {
                                Text("デバイスを探しています")
                                Image(systemName: "ellipsis")
                                    .symbolEffect(.variableColor.cumulative, options: .speed(10))
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    var connectedDevicesView: some View {
        WithViewStore(configStore, observe: { $0 }) { viewStore in
            if !MCManager.shared.connectedDevices.isEmpty {
                Section("接続済みデバイス") {
                    ForEach(viewStore.sharedState.connectedPeerInfos) { info in
                        Text(info.peerId.displayName)
                    }
                }
            }
        }
    }

    var appSettingView: some View {
        WithViewStore(configStore, observe: { $0 }) { viewStore in
            Section("アプリ設定") {
                Toggle(isOn: viewStore.binding { state in
                    viewStore.sharedState.isReadTextEnable
                } send: { _ in
                        .toggleReadTextEnable
                }, label: {
                    Text("文字の読み上げ")
                })

                Toggle(isOn: viewStore.binding { state in
                    viewStore.sharedState.isGuestReadTextEnable
                } send: { _ in
                        .toggleGuestReadTextEnable
                }, label: {
                    Text("相手の文字の読み上げ")
                })
                Toggle(isOn: viewStore.binding { state in
                    viewStore.sharedState.isReceiveMessageDisplayOnlyMode
                } send: { value in
                        .toggleReceiveMessageDisplayOnlyMode
                }, label: {
                    Text("相手の文字のみ表示")
                })
                NavigationLink {
                    EditUserDisplayNameView(configStore: configStore)
                } label: {
                    LabeledContent("表示名") {
                        Text(viewStore.sharedState.userDisplayName)
                    }
                }
            }
        }
    }

    var informationView: some View {
        Section("情報") {
            LabeledContent("デバイス名") {
                Text(Device.marketingName ?? Device.name)
            }
        }
    }

    var body: some View {
        WithViewStore(configStore, observe: { $0 }) { viewStore in
            NavigationStack {
                Form {
                    connectionSectionView
                    connectedDevicesView
                    appSettingView
                    informationView
#if os(macOS)
                    Spacer()
                        .frame(height: 40)
                    Button {
                        dismiss()
                    } label: {
                        Text("close")
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
#endif
                }
                .sheet(
                    isPresented: viewStore.binding(
                        get: \.isMcBrowserSheetPresented,
                        send: { ConfigReducer.Action.switchMcBrowserSheet(isPresented: $0) }
                    )
                ) {
                    NavigationStack {
                        MCBrowserViewControllerWrapper(serviceType: sessionType, peerID: myPeerID, session: session)
                            .navigationTitle(.init(String(localized: "Config.Widget.findDevices", defaultValue: "受信デバイスを探す")))
                    }
                }
                .navigationTitle(.init(String(localized: "Config.title", defaultValue: "設定")))
            }
        }
    }
}

#Preview {
    ConfigView(configStore: .init(initialState: .init(), reducer: {
        ConfigReducer()
    }))
}
