//
//  EmptyStateView.swift
//  Unhurry
//

import SwiftUI

/// 可复用的空状态占位组件。
struct EmptyStateView: View {

    let icon: String
    let title: String
    let subtitle: String
    var actionLabel: String?
    var action: (() -> Void)?

    private var accentColor: Color { Theme.accentColor }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(accentColor.opacity(0.35))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(accentColor.opacity(0.5))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(accentColor.opacity(0.35))
                .multilineTextAlignment(.center)
                .lineLimit(3)

            if let label = actionLabel, let action = action {
                Button(action: action) {
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accentColor.opacity(0.03))
        )
    }
}
