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
    //    @State private var isSenderEnable = true
    //    @State private var isBrowserViewPresented = false
    private let myPeerID = MCManager.shared.peerID
    private let session = MCManager.shared.mcSession
    private let sessionType = MCManager.shared.serviceType

    let store: StoreOf<Feature>

    var connectionSectionView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Section("接続モード") {
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
                        Text("ゲストデバイスを探す")
                    })
                    .buttonStyle(BorderlessButtonStyle())
                } else {
                    HStack {
                        Button(action: {
                            viewStore.send(.configAction(action: .didTapAdvertisingPeerButton))
                        }, label: {
                            Text(viewStore.mcState.isStartAdvertisingPeer ? "検索を停止する" : "ホストを探す")
                        })
                        .buttonStyle(BorderlessButtonStyle())
                        Spacer()
                        if viewStore.mcState.isStartAdvertisingPeer {
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

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                Form {
                    connectionSectionView
                    if !MCManager.shared.connectedDevices.isEmpty {
                        Section("接続済みデバイス") {
                            ForEach(viewStore.mcState.connectedPeerInfos) { info in
                                Text(info.peerId.displayName)
                            }
                        }
                    }
                    Section("情報") {
                        LabeledContent("デバイス情報") {
                            Text(Device.marketingName ?? Device.name)
                        }
                    }
                }
                .fullScreenCover(
                    isPresented: viewStore.binding(
                        get: \.isMcBrowserSheetPresented,
                        send: { .configAction(action: .setSheet(isPresented: $0)) }
                    )
                ) {
                    NavigationStack {
                        MCBrowserViewControllerWrapper(serviceType: sessionType, peerID: myPeerID, session: session)
                            .navigationTitle("受信デバイスを探す")
                            .navigationBarTitleDisplayMode(.inline)
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

                //                .alert(item: viewStore.mcState.$advertiserInvitationAlertState) { action in
                //                      self.model.alertButtonTapped(action)
                //                    }
                //                .alert(store: store.scope(
                //                    state: \.mcState.$advertiserInvitationAlertState,
                //                    action: { .advertiserInvitationAlert(action: $0) })
                //                )
                .navigationTitle("設定")
            }
        }
    }
}

#Preview {
    ConfigView(store: .init(initialState: .init(), reducer: {
        Feature()
    }))
}
