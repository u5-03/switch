//
//  MultipeerConnectivityState.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/23.
//

import Foundation
import MultipeerConnectivity
import ComposableArchitecture

enum MultipeerConnectivityDelegateAction: Equatable {
    case sessionDidChanaged(peerID: MCPeerID, state: MCSessionState)
    case sessionDidReceived(data: Data, peerID: MCPeerID)
    case advertiserDidReceiveInvitationFromPeer(peerID: MCPeerID, context: Data?, invitationHandler: (Bool, MCSession?) -> Void)
    case browserFound(browser: MCNearbyServiceBrowser, foundPeerId: MCPeerID, info: [String : String]?)
    case browserLost(browser: MCNearbyServiceBrowser, lostPeerId: MCPeerID)

    static func == (lhs: MultipeerConnectivityDelegateAction, rhs: MultipeerConnectivityDelegateAction) -> Bool {
        switch (lhs, rhs) {
        case let (.sessionDidChanaged(peerID1, state1), .sessionDidChanaged(peerID2, state2)):
            return peerID1 == peerID2 && state1 == state2
        case let (.sessionDidReceived(data1, peerID1), .sessionDidReceived(data2, peerID2)):
            return data1 == data2 && peerID1 == peerID2
        case let (.advertiserDidReceiveInvitationFromPeer(peerID1, context1, _), .advertiserDidReceiveInvitationFromPeer(peerID2, context2, _)):
            return peerID1 == peerID2 && context1 == context2
        case let (.browserFound(browser1, foundPeerId1, info1), .browserFound(browser2, foundPeerId2, info2)):
            return browser1 == browser2 && foundPeerId1 == foundPeerId2 && info1 == info2
        case let (.browserLost(browser1, lostPeerId1), .browserLost(browser2, lostPeerId2)):
            return browser1 == browser2 && lostPeerId1 == lostPeerId2
        default:
            return false
        }
    }
}

struct MultipeerConnectivityState: Equatable {
    var connectedPeerInfos: [PeerInfo] = []
    var connectionCandidatePeerInfos: [PeerInfo] = []
    var isStartAdvertisingPeer = false //
    var shouldShowAdvertiserInvitationAlert = false
    var userMode: MCMode = .host //
    var userDisplayName = "" { // 
        didSet {
            UserDefaults.standard.userDisplayName = userDisplayName
            if !userDisplayName.isEmpty {
                MCManager.shared.changePeerDisplayName(displayName: userDisplayName)
            }
        }
    }

    @PresentationState var browserViewPresentationState: MultipeerConnectivityState?

    init() {
        userDisplayName = UserDefaults.standard.userDisplayName
    }
}
