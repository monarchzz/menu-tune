//
//  CustomSlider.swift
//  MenuTune
//
//  Custom slider view for playback progress scrubbing.
//

import SwiftUI

// MARK: - Custom Slider

/// Custom slider for playback progress with draggable thumb.
struct CustomSlider: View {

    // MARK: - Properties

    @Binding var value: Double
    let range: ClosedRange<Double>
    let foregroundColor: Color
    let trackColor: Color

    @State private var isDragging = false
    @State private var isHovering = false

    private let height: CGFloat = 4
    private let thumbSize: CGFloat = 20

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - thumbSize

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                    .frame(maxHeight: .infinity, alignment: .center)

                // Progress track (filled portion)
                Capsule()
                    .fill(trackColor)
                    .frame(
                        width: progressWidth(in: availableWidth),
                        height: height
                    )
                    .frame(maxHeight: .infinity, alignment: .center)

                // Draggable thumb
                Circle()
                    .fill(foregroundColor)
                    .frame(width: thumbSize, height: thumbSize)
                    .scaleEffect(isDragging ? 1.2 : (isHovering ? 1.1 : 1.0))
                    .shadow(
                        color: .black.opacity(isDragging ? 0.3 : 0.2), radius: isDragging ? 4 : 2,
                        x: 0, y: 1
                    )
                    .offset(x: thumbOffset(in: availableWidth))
                    .frame(maxHeight: .infinity, alignment: .center)
                    .animation(.spring(duration: 0.3, bounce: 0.3), value: value)
                    .animation(.spring(duration: 0.2, bounce: 0.2), value: isDragging)
                    .animation(.spring(duration: 0.2, bounce: 0.2), value: isHovering)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                        }
                        let location = drag.location.x - thumbSize / 2
                        let clampedX = min(max(0, location), availableWidth)
                        let relative = clampedX / availableWidth
                        let newValue =
                            range.lowerBound + (range.upperBound - range.lowerBound)
                            * Double(relative)
                        value = newValue
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .sensoryFeedback(.selection, trigger: isDragging)
        }
        .frame(height: thumbSize)
    }

    // MARK: - Private Methods

    private func progressWidth(in availableWidth: CGFloat) -> CGFloat {
        guard range.upperBound > range.lowerBound else { return thumbSize / 2 }
        let clampedValue = max(range.lowerBound, min(range.upperBound, value))
        let percent = (clampedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(percent) * availableWidth + thumbSize / 2
    }

    private func thumbOffset(in availableWidth: CGFloat) -> CGFloat {
        progressWidth(in: availableWidth) - thumbSize / 2
    }
}

// MARK: - Preview

#Preview("Default Slider") {
    @Previewable @State var value = 50.0

    CustomSlider(
        value: $value,
        range: 0...100,
        foregroundColor: .white,
        trackColor: .blue
    )
    .padding()
    .background(.gray)
}
