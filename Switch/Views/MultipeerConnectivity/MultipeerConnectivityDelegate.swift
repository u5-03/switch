//
//  MultipeerConnectivityDelegate.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import Foundation
import MultipeerConnectivity
import ComposableArchitecture
import Combine


struct MultipeerConnectivitySendableBox: Sendable {
    @UncheckedSendable var manager: MCManager
    var delegate: MultipeerConnectivityDelegate
}


final class MultipeerConnectivityDelegate: NSObject, Sendable {
    let continuations: ActorIsolated<[UUID: AsyncStream<MultipeerConnectivityDelegateAction>.Continuation]>

    override init() {
        self.continuations = .init([:])
        super.init()
    }

    func registerContinuation(_ continuation: AsyncStream<MultipeerConnectivityDelegateAction>.Continuation) {
        Task { [continuations] in
            await continuations.withValue {
                let id = UUID()
                $0[id] = continuation
                continuation.onTermination = { [weak self] _ in self?.unregisterContinuation(withID: id) }
            }
        }
    }

    private func unregisterContinuation(withID id: UUID) {
        Task { [continuations] in await continuations.withValue { $0.removeValue(forKey: id) } }
    }

    private func send(_ action: MultipeerConnectivityDelegateAction) {
        Task { [continuations] in
            await continuations.withValue { $0.values.forEach { $0.yield(action) } }
        }
    }
}

extension MultipeerConnectivityDelegate: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let message: String
        switch state {
        case .connected:
            message = "\(peerID.displayName)が接続されました"
        case .connecting:
            message = "\(peerID.displayName)が接続中です"
        case .notConnected:
            message = "\(peerID.displayName)が切断されました"
        @unknown default:
            message = "\(peerID.displayName)が想定外の状態です"
        }
        print("session: didChange, \(message)")
        send(.sessionDidChanaged(peerID: peerID, state: state))
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("session: didReceive, \(peerID.displayName)")
        send(.sessionDidReceived(data: data, peerID: peerID))
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

        print("session: didReceive stream, \(peerID.displayName)")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

        print("session: didStartReceivingResourceWithName, \(peerID.displayName)")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("session: didFinishReceivingResourceWithName, \(peerID.displayName)")
    }
}

extension MultipeerConnectivityDelegate: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        //        invitationHandler(true, mcSession)
        // 周囲のデバイスにこのデバイスの情報が表示されるようになる
        send(.advertiserDidReceiveInvitationFromPeer(peerID: peerID, context: context, invitationHandler: invitationHandler))
    }
}

extension MultipeerConnectivityDelegate: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Will invite peer: \(peerID.displayName)")
        //        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 0)
        send(.browserFound(browser: browser, foundPeerId: peerID, info: info))
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        send(.browserLost(browser: browser, lostPeerId: peerID))
    }
}


