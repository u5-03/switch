//
//  MultipeerConnectivityView.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/19.
//

import SwiftUI
import MultipeerConnectivity

struct MultipeerConnectivityView: View {
    @State private var isBrowserViewPresented = false
    private let myPeerID = MCManager.shared.peerID
    private let session = MCManager.shared.mcSession
    private let sessionType = MCManager.shared.serviceType

    var body: some View {
        VStack {
            Button("Show Browser View") {
                isBrowserViewPresented.toggle()
            }

            Button("Start Hosting") {
                MCManager.shared.startAdvertisingPeer()
            }

            Button("Send Message") {
                MCManager.shared.sendMessage()
            }
            .fullScreenCover(isPresented: $isBrowserViewPresented, content: {
                MCBrowserViewControllerWrapper(serviceType: sessionType, peerID: myPeerID, session: session)
            })
        }
    }
}

#Preview {
    MultipeerConnectivityView()
}
