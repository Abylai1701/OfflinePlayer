//
//  SafariView.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 22.08.2025.
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var barColor: UIColor = .black
    var controlColor: UIColor = .white
    var dismissStyle: SFSafariViewController.DismissButtonStyle = .close

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false

        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredBarTintColor = barColor
        vc.preferredControlTintColor = controlColor
        vc.dismissButtonStyle = dismissStyle  
        return vc
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
