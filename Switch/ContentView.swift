//
//  ContentView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/11.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isConfigPresented = false

    init() {

    }

    var body: some View {
        ChatListView(store: .init(initialState: .init(), reducer: {
            Feature()
        }))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
