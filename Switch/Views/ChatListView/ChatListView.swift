//
//  ChatListView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/11.
//

import SwiftUI
import Combine
import ComposableArchitecture

@MainActor
struct ChatListView: View {
    let chatListStore: StoreOf<ChatListReducer>
    @State var text = ""
    @State var isFlag = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var storeTask: StoreTask?

    private var scrollView: some View {
        WithViewStore(chatListStore, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewStore.adjustedMessages) { type in
                        HStack {
                            ChatBubbleView(
                                type: type,
                                isReceiveMessageDisplayOnlyMode: UserDefaults.standard.isReceiveMessageDisplayOnlyMode) { action in
//                                isReceiveMessageDisplayOnlyMode: viewStore.mcState.isReceiveMessageDisplayOnlyMode) { action                                     in
                                    switch action {
                                    case .delete(let messageItem):
                                        viewStore.send(.didTapMessageDeleteButton(messageItem: messageItem))
                                    case .retry(let messageItem):
                                        viewStore.send(.readErrorMessage(messageItem: messageItem))
                                    }
                                }
                            Spacer()
                        }
                        .id(type.messageItem.id)
                        .transition(.opacity)
                    }
                    Spacer()
                        .frame(height: 16)
                }
                .padding()
            }
        }
    }

    private var textFieldView: some View {
        return WithViewStore(chatListStore, observe: { $0 }) { viewStore in
            HStack {
                TextField("Enter text", text: viewStore.binding(get: \.newMessage, send: ChatListReducer.ChatListAction.textChanged))
                // axis: .verticalを指定すると、macのキーボードで入力した時に、Enterが効かなくなるので、一時的に外す
//                TextField("Enter text", text: viewStore.binding(get: \.newMessage, send: Feature.Action.textChanged), axis: .vertical)
                    .autocorrectionDisabled()
                // これがないと、最初の日本語文字入力時に、確定状態になる
                    .submitLabel(.send)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                Button(action: {
                    if !viewStore.newMessage.trimmed().isEmpty {
                        isTextFieldFocused = false
                        _ = withAnimation(.easeInOut) {
                            viewStore.send(.didTapSendButton)
                        } completion: {
                            viewStore.send(.willScrollToBottom)
                        }
                    }
                }, label: {
                    Image(systemName: "paperplane.fill")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                })
                .controlSize(.regular)
            }
            .padding()
        }
    }

    var body: some View {
        WithViewStore(chatListStore, observe: { $0 }) { viewStore in
            NavigationStack {
                ScrollViewReader { scrollViewProxy in
                    // Listを使うと、insertのアニメーションとscrollToBottomのアニメーションがうまく動かない
                    scrollView
                    textFieldView
                        .onReceive(viewStore.publisher.scrollToRowId) { scrollToRowId in
                            if let scrollToRowId {
                                scrollToBottom(id: scrollToRowId, scrollViewProxy: scrollViewProxy, viewStore: viewStore)
                            }
                        }
                }
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .navigationTitle("Switch")
            }
            .task {
                storeTask?.cancel()
                storeTask = viewStore.send(.task)
                // 以下のコードでは、tabを切り替えた時にcancelされてしまい、streamの変更を受け取ることができない￥
                // viewStore.send(.task).finish()
            }
        }
    }
}

private extension ChatListView {
    func scrollToBottom(id: String, scrollViewProxy: ScrollViewProxy, viewStore: ViewStore<ChatListReducer.State, ChatListReducer.Action>) {
        DispatchQueue.main.async {
            withAnimation {
                scrollViewProxy.scrollTo(id)
                print("Did complete messages animation \(id)")
            } completion: {
                viewStore.send(.didScrollToBottom)
            }
        }
    }
}

#Preview {
    ChatListView(chatListStore: .init(initialState: .init(), reducer: {
        ChatListReducer()
    }))
}
