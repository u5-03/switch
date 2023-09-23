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
                    ForEach(viewStore.messages) { messageItem in
                        HStack {
                            ChatBubbleView(
                                item: messageItem,
                                mirrored: true
                            )
                            .onTapGesture {
                                Task {
                                    switch messageItem.readingStatus {
                                    case .readingError:
                                        viewStore.send(.readErrorMessage(messageItem: messageItem))
                                    case .willRead:
                                        viewStore.send(.deleteMessage(messageItem: messageItem))
                                    default:
                                        break
                                    }
                                }
                            }
                            Spacer()
                        }
                        .id(messageItem.id)
                        .transition(.opacity)
                        //                    .transition(
                        //                        AnyTransition.asymmetric(
                        //                            insertion: AnyTransition.slide.combined(with: AnyTransition.opacity),
                        //                            removal: AnyTransition.slide.combined(with: AnyTransition.opacity)
                        //                        )
                        //                    )
                    }
                    // Ref: https://www.hackingwithswift.com/forums/swiftui/scrollviewproxy-scrollto-seems-to-be-broken-on-ios-16/16318/18295
                    //                .id(listID)
                    //                .id(UUID())
                    //                .onAppear {
                    //                    UITableView.appearance().separatorStyle = .none
                    //                }
                    //                .onChange(of: state.messages, initial: true) {
                    //                    //                    scrollToBottom(scrollViewProxy: scrollViewProxy)
                    //                }
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
                        TextField("Enter text", text: viewStore.binding(get: { state in
                            state.newMessage
                        }, send: Feature.Action.textChanged), axis: .vertical)
                        .submitLabel(.send)
                        .textFieldStyle(.roundedBorder)
                        Button(action: {
                            if !viewStore.newMessage.trimmed().isEmpty {
                                withAnimation(.spring) {
                                    viewStore.send(.addMessage(text: viewStore.newMessage.trimmed()))
                                    // iOS17~/macOS14〜ではwithAnimationのcompletionを使用する
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        scrollToBottom(id: viewStore.messages.last?.id ?? "", scrollViewProxy: scrollViewProxy)
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
                            viewStore.send(.toggleConfigurePresenterd)
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .tint(Color(.systemGray))
                        }
                    }
                }
                .sheet(
                    isPresented: viewStore.binding(
                        get: { $0.isConfigPresented },
                        send: { .toggleConfigurePresenterd}()
                    ), content: {
                        ConfigView()
                    }
                )
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
