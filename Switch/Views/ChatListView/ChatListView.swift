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
    //    @State private var state = ChartListState()
    let store: StoreOf<Feature>

    private var scrollView: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewStore.messages) { type in
                        HStack {
                            ChatBubbleView(
                                type: type,
                                mirrored: true
                            )
                            .onTapGesture {
                                Task {
                                    switch type.messageItem.readingStatus {
                                    case .readingError:
                                        viewStore.send(.readErrorMessage(messageItem: type.messageItem))
                                    case .willRead:
                                        viewStore.send(.didTapMessageDeleteButton(messageItem: type.messageItem))
                                    default:
                                        break
                                    }
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

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                ScrollViewReader { scrollViewProxy in
                    // Listを使うと、insertのアニメーションとscrollToBottomのアニメーションがうまく動かない
                    scrollView
                    HStack {
                        TextField("Enter text", text: viewStore.binding(get: \.newMessage, send: Feature.Action.textChanged), axis: .vertical)
                            // これがないと、最初の日本語文字入力時に、確定状態になる
                            .disableAutocorrection(true)
                            .submitLabel(.send)
                            .textFieldStyle(.roundedBorder)
                        Button(action: {
                            if !viewStore.newMessage.trimmed().isEmpty {
                                withAnimation(.spring) {
                                    viewStore.send(.didTapSendButton)
                                    // iOS17~/macOS14〜ではwithAnimationのcompletionを使用する
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        scrollToBottom(id: viewStore.messages.last?.messageItem.id ?? "", scrollViewProxy: scrollViewProxy)
                                    }
                                }

                            }
                        }, label: {
                            Text("Send")
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
                .navigationTitle("Switch")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            viewStore.send(.didTapConfigButton)
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .tint(Color(.systemGray))
                        }
                    }
                }
                .sheet(
                    isPresented: viewStore.binding(
                        get: { $0.isConfigPresented },
                        send: { .toggleConfigButtonPresented}()
                    ), content: {
                        ConfigView(store: store)
                    }
                )
                .task { await viewStore.send(.task).finish() }
            }
        }
    }
}

private extension ChatListView {
    func scrollToBottom(id: String, scrollViewProxy: ScrollViewProxy) {
        withAnimation {
            scrollViewProxy.scrollTo(id)
            print("Did complete messages animation")
        }
    }
}

#Preview {
    ChatListView(store: .init(initialState: .init(), reducer: {
        Feature()
    }))
}
