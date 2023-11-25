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
    private let myPeerID = MCManager.shared.peerID
    private let session = MCManager.shared.mcSession
    private let sessionType = MCManager.shared.serviceType

    let store: StoreOf<Feature>

    var connectionSectionView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Section(String(localized: "Config.section.title.connectionMode", defaultValue: "接続モード")) {
                Toggle(isOn: viewStore.binding { state in
                    state.mcState.userMode == .host
                } send: { value in
                        .configAction(action: .switchHostMode)
                }, label: {
                    Text(viewStore.state.mcState.userMode.displayName)
                })
                if viewStore.state.mcState.userMode == .host {
                    Button(action: {
                        viewStore.send(.configAction(action: .setSheet(isPresented: true)))
                    }, label: {
                        Text(String(localized: "Config.findGuests", defaultValue: "ゲストデバイスを探す"))
                    })
                    .buttonStyle(BorderlessButtonStyle())
                } else {
                    HStack {
                        Button(action: {
                            viewStore.send(.configAction(action: .didTapAdvertisingPeerButton))
                        }, label: {
                            Text(viewStore.mcState.isStartAdvertisingPeer ? String(localized: "Config.stopSearch", defaultValue: "検索を停止する") : String(localized: "Config.searchHost", defaultValue: "ホストを探す"))
                        })
                        .buttonStyle(BorderlessButtonStyle())
                        Spacer()
                        if viewStore.mcState.isStartAdvertisingPeer {
                            HStack(spacing: 2) {
                                Text(String(localized: "Config.seachDevices", defaultValue: "デバイスを探しています"))
                                Image(systemName: "ellipsis")
                                    .symbolEffect(.variableColor.cumulative, options: .speed(10))
                            }
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                Form {
                    connectionSectionView
                    if !MCManager.shared.connectedDevices.isEmpty {
                        Section(String(localized: "Config.section.title.connectedDevice", defaultValue: "接続済みデバイス")) {
                            ForEach(viewStore.mcState.connectedPeerInfos) { info in
                                Text(info.peerId.displayName)
                            }
                        }
                    }
                    Section(String(localized: "Config.section.title.appConfig", defaultValue: "アプリ設定")) {
                        Toggle(isOn: viewStore.binding { state in
                            state.mcState.isReadTextEnable
                        } send: { value in
                                .configAction(action: .toggleReadTextEnable)
                        }, label: {
                            Text(String(localized: "Config.readText", defaultValue: "文字の読み上げ"))
                        })
                        Toggle(isOn: viewStore.binding { state in
                            state.mcState.isGuestReadTextEnable
                        } send: { value in
                                .configAction(action: .toggleGuestReadTextEnable)
                        }, label: {
                            Text(String(localized: "Config.readOnlyOppsiteText", defaultValue: "相手の文字の読み上げ"))
                        })
                        Toggle(isOn: viewStore.binding { state in
                            state.mcState.isReceiveMessageDisplayOnlyMode
                        } send: { value in
                                .configAction(action: .toggleReceiveMessageDisplayOnlyMode)
                        }, label: {
                            Text(String(localized: "Config.toggleOnlyOppositeText", defaultValue: "相手の文字のみ表示"))
                        })
                        NavigationLink {
                            EditUserDisplayNameView(store: store)
                        } label: {
                            LabeledContent(String(localized: "Config.displayName", defaultValue: "表示名")) {
                                Text(viewStore.mcState.userDisplayName)
                            }
                        }
                    }
                    Section(String(localized: "Config.section.title.information", defaultValue: "情報")) {
                        LabeledContent(String(localized: "Config.DeviceName", defaultValue: "デバイス名")) {
                            Text(Device.marketingName ?? Device.name)
                        }
                    }
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
                        send: { .configAction(action: .setSheet(isPresented: $0)) }
                    )
                ) {
                    NavigationStack {
                        MCBrowserViewControllerWrapper(serviceType: sessionType, peerID: myPeerID, session: session)
                            .navigationTitle(String(localized: "Config.title", defaultValue: "受信デバイスを探す"))
//                            .toolbar {
//                                ToolbarItem {
//                                    Button {
//                                        dismiss()
//                                    } label: {
//                                        Text("閉じる")
//                                    }
//                                }
//                            }
                    }
                }
                .alert(
                    store: store.scope(
                        state: \.$advertiserInvitationAlertState,
                        action: { Feature.Action.advertiserInvitationAlert(action: $0) }
                    ), state: { state in
                        state
                    }, action: { $0 }
                )
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            dismiss()
                        } label: {
                            Text(String(localized: "close", defaultValue: "閉じる"))
                        }
                    }
                }
                .navigationTitle(String(localized: "Config.title", defaultValue: "設定"))
            }
        }
    }
}

#Preview {
    ConfigView(store: .init(initialState: .init(), reducer: {
        Feature()
    }))
}
