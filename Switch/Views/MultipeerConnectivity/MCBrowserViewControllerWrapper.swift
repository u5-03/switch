//
//  MCBrowserViewControllerWrapper.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/19.
//

import SwiftUI
#if os(iOS)
import UIKit
typealias ViewControllerRepresentable = UIViewControllerRepresentable
#elseif os(macOS)
typealias ViewControllerRepresentable = NSViewControllerRepresentable
typealias NSViewControllerType = MCBrowserViewController
import AppKit
#endif
import MultipeerConnectivity

struct MCBrowserViewControllerWrapper: ViewControllerRepresentable {
#if os(iOS)
    typealias UIViewControllerType = MCBrowserViewController
#elseif os(macOS)
    typealias NSViewControllerType = MCBrowserViewController
#endif

    final class Coordinator: NSObject, MCBrowserViewControllerDelegate {
        var parent: MCBrowserViewControllerWrapper

        init(parent: MCBrowserViewControllerWrapper) {
            self.parent = parent
        }

        func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
            dismissBrowser(browserViewController: browserViewController)
        }

        func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
            dismissBrowser(browserViewController: browserViewController)
        }

        private func dismissBrowser(browserViewController: MCBrowserViewController) {
#if os(iOS)
            browserViewController.dismiss(animated: true)
#elseif os(macOS)
            browserViewController.dismiss(true)
#endif
        }
    }

    var serviceType: String
    var peerID: MCPeerID
    var session: MCSession

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeViewController(context: Context) -> MCBrowserViewController {
        let browserViewController = MCBrowserViewController(serviceType: serviceType, session: session)
        browserViewController.delegate = context.coordinator
        return browserViewController
    }

#if os(iOS)
    func makeUIViewController(context: Context) -> MCBrowserViewController {
        return makeViewController(context: context)
    }

    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) {}
#elseif os(macOS)
    func makeNSViewController(context: Context) -> MCBrowserViewController {
        return makeViewController(context: context)
    }

    func updateNSViewController(_ nsViewController: MCBrowserViewController, context: Context) {

    }
#endif

}

