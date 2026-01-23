//
//  StatusItemView.swift
//  MenuTune
//
//  SwiftUI view for the status bar item displaying player icon and track info.
//

import SwiftUI

// MARK: - Status Item View

/// SwiftUI view displayed in the menu bar status item.
struct StatusItemView: View {

    @ObservedObject var statusModel: StatusItemModel
    @ObservedObject var preferences: PreferencesModel

    // MARK: - Constants

    private let iconSize: CGFloat = 16
    private let spacing: CGFloat = 4

    // MARK: - Computed Properties

    private var displayOptions: StatusItemDisplayOptions {
        statusModel.computeDisplayOptions(preferences: preferences)
    }

    private var displayText: String {
        let font = NSFont.menuBarFont(ofSize: 0)
        return statusModel.buildText(
            displayOptions: displayOptions, preferences: preferences, font: font)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            // Player app icon
            if displayOptions.showIcon {
                let iconName = statusModel.playerIconName
                if iconName.hasPrefix("sf.") {
                    Image(systemName: String(iconName.dropFirst(3)))
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                } else {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(Circle())
                }
            }

            // Music note when playing
            if displayOptions.showMusicIcon {
                Text("♫")
                    .font(.system(size: 12))
                    .contentTransition(.symbolEffect(.replace))
            }

            // Artist - Title text
            if displayOptions.showText && !displayText.isEmpty {
                Text(displayText)
                    .font(.menuBarText(weight: preferences.menuBarFontWeight.weight))
                    .lineLimit(1)
                    .padding(.horizontal, preferences.compactView ? 0 : 4)
                    .contentTransition(.interpolate)
                    .animation(.spring(duration: 0.3), value: displayText)
            }
        }
        .frame(height: 22)
        .fixedSize()
    }

    // MARK: - Preview

    // Preview disabled - requires full app context
    //     StatusItemView(statusModel: StatusItemModel(), preferences: PreferencesModel())
    // }
}
