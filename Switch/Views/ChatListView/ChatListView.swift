//
//  ChatListView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/11.
//

import SwiftUI
import Combine

@MainActor
struct ChatListView: View {
    @State private var state = ChartListState()

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            // Listを使うと、insertのアニメーションとscrollToBottomのアニメーションがうまく動かない
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(state.messages) { messageItem in
                        HStack {
                            ChatBubbleView(
                                item: messageItem,
                                mirrored: true
                            )
                            .onTapGesture {
                                Task {
                                    switch messageItem.readingStatus {
                                    case .readingError:
                                        await state.readErrorText(messageItem: messageItem)
                                    case .willRead:
                                        state.deleteMessage(messageItem: messageItem)
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
                    .onChange(of: state.messages, initial: true) {
                        //                    scrollToBottom(scrollViewProxy: scrollViewProxy)
                    }
                    Spacer()
                        .frame(height: 16)
                }
            }
            HStack {
                TextField("Enter text", text: $state.newMessage, axis: .vertical)
                    .submitLabel(.send)
                    .textFieldStyle(.roundedBorder)
                Button(action: {
                    if !state.newMessage.trimmed().isEmpty {
                        addMessage(text: state.newMessage.trimmed(), scrollViewProxy: scrollViewProxy)
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
    }
}

private extension ChatListView {
    func addMessage(text: String, scrollViewProxy: ScrollViewProxy) {
        withAnimation(.spring) {
            state.addMessage(text: text)
            // iOS17~/macOS14〜ではwithAnimationのcompletionを使用する
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                scrollToBottom(scrollViewProxy: scrollViewProxy)
            }
        }
    }

    func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        withAnimation {
            scrollViewProxy.scrollTo(state.messages.last?.id ?? "")
            print("Did complete messages animation")
        }
    }
}

#Preview {
    ChatListView()
}
