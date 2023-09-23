//
//  MultipeerConnectivityState.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import Foundation
import MultipeerConnectivity

struct DeviceInfo: Identifiable {
    let id = UUID().uuidString
    let deviceName: String
}

final class MultipeerConnectivityState: NSObject {
    let peerID: MCPeerID
    let mcSession: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    let serviceType = "switch-app"

    var connectedDevices: [DeviceInfo] {
        return mcSession.connectedPeers
            .map { DeviceInfo(deviceName: $0.displayName) }
    }

    private override init() {
        peerID = MCPeerID(displayName: Device.marketingName ?? Device.name)
        mcSession = MCSession(peer: peerID)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        super.init()

        mcSession.delegate = self
        advertiser.delegate = self
    }
}

extension MultipeerConnectivityState {

}


extension MultipeerConnectivityState: MCSessionDelegate {
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
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("session: didReceive, \(peerID.displayName)")
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

extension MultipeerConnectivityState: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }
}

extension MultipeerConnectivityState: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Will invite peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 0)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {

    }
}

