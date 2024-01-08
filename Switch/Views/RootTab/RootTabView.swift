//
//  RootTabView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/11/05.
//

import SwiftUI
import ComposableArchitecture

struct RootTabView: View {
    let store: StoreOf<RootTabReducer>
    @State var selection = ""

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                TabView(selection: viewStore.binding(get: { state in
                    state.selectedTab
                }, send: { value in
                        .didChangedTab(tab: value)
                }))  {
                    ChatListView(chatListStore: store.scope(state: { state in
                        state.chatListState
                    }, action: { childAction in
                        RootTabReducer.RootTabAction.chatListAction(childAction)
                    }))
                    .tabItem {
                        Label("Chat", systemImage: "message")
                    }
                    .tag(RootTabKind.chatList.displayText)

                    ConfigView(configStore: store.scope(state: { state in
                        state.configState
                    }, action: { childAction in
                        RootTabReducer.RootTabAction.configAction(childAction)
                    }))
                        .tabItem {
                            Label("Config", systemImage: "gearshape.fill")
                        }
                        .tag(RootTabKind.config.displayText)
                }
                .navigationTitle(viewStore.selectedTab)
                .alert(store: store.scope(state: \.$advertiserInvitationAlertState, action: RootTabReducer.Action.advertiserInvitationAlert))
                .task {
                    viewStore.send(.task)
                }
            }
        }
    }
}

#Preview {
    RootTabView(store: .init(initialState: .init(), reducer: {
        RootTabReducer()
    }))
}
