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
    let store1 = Store(
        initialState: HogeReducer.HogeState(),
        reducer: {
            HogeReducer()
        }
    )
    let store2 = Store(
        initialState: HogeReducer.HogeState(),
        reducer: {
            HogeReducer()
        }
    )

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
            }
        }
    }
}

#Preview {
    RootTabView(store: .init(initialState: .init(), reducer: {
        RootTabReducer()
    }))
}

//struct HogeView: View {
//    let store: StoreOf<HogeReducer>
//    @Dependency(\.sharedState.store) var sharedStore
//
//    var body: some View {
//        WithViewStore(store, observe: { $0 }) { viewStore in
//            VStack(spacing: 8) {
//                Text(viewStore.name)
//                Button(action: {
//                    viewStore.send(.updateName(.random))
//                }, label: {
//                    Text("Update Name")
//                })
//                Divider()
//                WithViewStore(sharedStore, observe: { $0 }) { viewStore in
////                    Text(viewStore.text)
//                }
//                Button(action: {
////                    viewStore.send(.updateSharedText(.random))
//                }, label: {
//                    Text("Update SharedText")
//                })
//            }
//        }
//    }
//}

struct HogeReducer: Reducer {
    typealias State = HogeReducer.HogeState
    @Dependency(\.sharedState) var sharedClient

    struct HogeState: Equatable, Hashable {
        var name = ""
    }

    enum Action {
        case updateName(String)
//        case updateSharedText(String)
    }

    var body: some Reducer<HogeReducer.HogeState, HogeReducer.Action> {
        Reduce { state, action in
            switch(action) {
            case .updateName(let name):
                state.name = name
                return .none
//            case .updateSharedText(let text):
//                sharedClient.store.send(.updateText(text))
//                return .none
            }
        }
    }
}
