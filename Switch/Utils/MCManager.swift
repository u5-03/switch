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

    let peerID: MCPeerID
    let mcSession: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    private(set) var stream: AsyncStream<MultipeerConnectivityDelegateAction>?

    let serviceType = "switch-app"
//    var delegate: MultipeerConnectivityDelegate?

    var connectedDevices: [DeviceInfo] {
        return mcSession.connectedPeers
            .map { DeviceInfo(deviceName: $0.displayName) }
    }

    private init() {
        peerID = MCPeerID(displayName: Device.marketingName ?? Device.name)
        mcSession = MCSession(peer: peerID)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)

//        stream = AsyncStream<MultipeerConnectivityDelegateAction> { continuation in
//            delegate = MultipeerConnectivityDelegate(actionHandler: { action in
//                continuation.yield(action)
//            })
//        }
    }

    func setDelegate(delegate: MultipeerConnectivityDelegate) {
        mcSession.delegate = delegate
        advertiser.delegate = delegate
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
