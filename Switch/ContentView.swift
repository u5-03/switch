//
//  ContentView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/11.
//

import SwiftUI
import AVFoundation

struct ContentView: View {

    init() {
        if UserDefaults.standard.userDisplayName.isEmpty {
            UserDefaults.standard.userDisplayName = Device.marketingName ?? Device.name
        }
    }

    var body: some View {
        RootTabView(store: .init(initialState: .init(), reducer: {
            RootTabReducer()
        }))
//        ChatListView(store: .init(initialState: .init(), reducer: {
//            Feature()
//                .dependency(\.multipeerConnectivityClient, .liveValue)
////                .dependency(\.multipeerConnectivityClient, .mock)
//        }))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
