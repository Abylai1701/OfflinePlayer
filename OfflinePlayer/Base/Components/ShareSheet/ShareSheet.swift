//
//  ShareSheet.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 25.08.2025.
//

import Foundation
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var activities: [UIActivity]? = nil
    var completion: UIActivityViewController.CompletionWithItemsHandler? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: activities)
        vc.completionWithItemsHandler = completion
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
