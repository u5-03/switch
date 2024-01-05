//
//  RootTabReducer.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/11/05.
//

import Foundation
import ComposableArchitecture

enum RootTabKind: String {
    case chatList
    case config

    var displayText: String {
        switch self {
        case .chatList: return "チャット"
        case .config: return "設定"
        }
    }
}

struct RootTabReducer: Reducer {
    typealias State = RootTabReducer.RootTabState
    typealias Action = RootTabReducer.RootTabAction

    struct RootTabState: Equatable {
        var selectedTab = RootTabKind.chatList.rawValue
        var chatListState: ChatListReducer.ChatListState = .init()
        var configState: ConfigReducer.ConfigState = .init()
    }

    enum RootTabAction {
        case didChangedTab(tab: String)
        case chatListAction(ChatListReducer.Action)
        case configAction(ConfigReducer.ConfigAction)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.configState, action: /RootTabAction.configAction) {
          ConfigReducer()
        }
        Scope(state: \.chatListState, action: /RootTabAction.chatListAction) {
          ChatListReducer()
        }
        Reduce { state, action in
            switch(action) {
            case .didChangedTab(let tab):
                state.selectedTab = tab
                return .none
            case .chatListAction:
                return .none
            case .configAction:
                return .none
            }
        }
    }
}
