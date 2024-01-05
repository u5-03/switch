//
//  EditUserDisplayNameView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/30.
//

import SwiftUI
import ComposableArchitecture

struct EditUserDisplayNameView: View {
    let configStore: StoreOf<ConfigReducer>

    init(configStore: StoreOf<ConfigReducer>) {
        self.configStore = configStore
#if os(iOS)
        UITextField.appearance().clearButtonMode = .whileEditing
#endif
    }

    var body: some View {
        WithViewStore(configStore, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack {
                    TextField(viewStore.sharedState.userDisplayName, text:
                                Binding(get: {
                        return viewStore.sharedState.userDisplayName
                    }, set: { value, _ in
                        viewStore.send(.didChangedUserDisplayNameText(name: value))
                    }))
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    Spacer()
                }
                .navigationTitle("表示名の変更")
            }
        }
    }
}

#Preview {
    EditUserDisplayNameView(configStore: .init(initialState: .init(), reducer: {
        ConfigReducer()
    }))
}
