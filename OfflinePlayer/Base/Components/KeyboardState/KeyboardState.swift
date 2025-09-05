//
//  KeyboardState.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 03.09.2025.
//

import Combine
import SwiftUI

final class KeyboardState: ObservableObject {
    @Published var visible = false

    private var bag = Set<AnyCancellable>()

    init() {
        let willChange = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)

        willChange.merge(with: willHide)
            .map { n in
                guard let end = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return false }
                return end.minY < UIScreen.main.bounds.height
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.visible = v }
            .store(in: &bag)
    }
}
