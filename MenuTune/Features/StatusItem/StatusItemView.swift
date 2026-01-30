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

    var statusModel: StatusItemModel
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
            if displayOptions.showText {
                if preferences.compactView {
                    VStack(alignment: .leading, spacing: -2) {
                        if displayOptions.showArtist {
                            Text(statusModel.artist)
                                .lineLimit(1)
                                .font(
                                    .system(
                                        size: 10, weight: preferences.fontWeightCompactTop.weight))
                        }
                        if displayOptions.showTitle {
                            Text(statusModel.title)
                                .lineLimit(1)
                                .font(
                                    .system(
                                        size: 9, weight: preferences.fontWeightCompactBottom.weight)
                                )
                        }
                    }
                    .frame(maxWidth: preferences.maxStatusItemWidth)
                    .padding(.horizontal, 0)
                } else if !displayText.isEmpty {
                    Text(displayText)
                        .font(.menuBarText(weight: preferences.fontWeightNormal.weight))
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .contentTransition(.interpolate)
                        .animation(.spring(duration: 0.3), value: displayText)
                }
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
