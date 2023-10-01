//
//  MCManager.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/18.
//

import Foundation
import MultipeerConnectivity

struct DeviceInfo: Identifiable {
    let id = UUID().uuidString
    let deviceName: String
}

// Ref: https://qiita.com/am10/items/e56c2bc6eaab75bc9c8c
final class MCManager {
    static let shared = MCManager()

    private(set) var peerID: MCPeerID
    private(set) var mcSession: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    private(set) var stream: AsyncStream<MultipeerConnectivityDelegateAction>?
//    private weak var delegate: MultipeerConnectivityDelegate?
    private var peerDisplayId = ""

    let serviceType = "switch-app"

    var connectedDevices: [DeviceInfo] {
        return mcSession.connectedPeers
            .map { DeviceInfo(deviceName: $0.displayName) }
    }

    private init() {
        peerID = MCPeerID(displayName: UserDefaults.standard.userDisplayName)
        mcSession = MCSession(peer: peerID)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
    }

    func setDelegate(delegate: MultipeerConnectivityDelegate) {
//        self.delegate = delegate
        mcSession.delegate = delegate
        advertiser.delegate = delegate
    }

    func changePeerDisplayName(displayName: String) {
        peerID = MCPeerID(displayName: displayName)
        mcSession = MCSession(peer: peerID)
//        guard let delegate else { return }
//        setDelegate(delegate: delegate)
    }

    func presentDeviceBrowser() {
        
    }

    func startAdvertisingPeer() {
        advertiser.startAdvertisingPeer()
    }

    func stopAdvertisingPeer() {
        advertiser.stopAdvertisingPeer()
    }

    func join() {}

    func sendMessage(text: String) {
        print(text)
        do {
            try mcSession.send(text.data(using: .utf8)!, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
