//
//  PresetRow.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 12.09.2025.
//

import SwiftUI

private struct PresetRow: View {
    
    // MARK: - Properties
    
    let preset: EQPreset
    let isSelected: Bool
    let onSelect: () -> Void
    
    // MARK: - Body

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(preset.name)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 45.fitH)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(
            Divider().background(.gray2C2C2C.opacity(0.8)),
            alignment: .bottom
        )
        .padding(.horizontal)
    }
}
