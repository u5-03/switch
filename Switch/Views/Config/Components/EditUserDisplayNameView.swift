//
//  EditUserDisplayNameView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/30.
//

import SwiftUI
import ComposableArchitecture

struct EditUserDisplayNameView: View {
    let store: StoreOf<Feature>

    init(store: StoreOf<Feature>) {
        self.store = store
#if os(iOS)
        UITextField.appearance().clearButtonMode = .whileEditing
#endif
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack {
                    TextField(viewStore.mcState.userDisplayName, text:
                                Binding(get: {
                        return viewStore.mcState.userDisplayName
                    }, set: { value, _ in
                        viewStore.send(.configAction(action: .didChangedUserDisplayNameText(name: value)))
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
    EditUserDisplayNameView(store: .init(initialState: .init(), reducer: {
        Feature()
    }))
}
