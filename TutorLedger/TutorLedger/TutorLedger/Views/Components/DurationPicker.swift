import SwiftUI

struct TLDurationPicker: View {
    @Binding var hours: Double
    var presets: [Double]

    @State private var customText = ""
    @State private var isCustomMode = false

    init(hours: Binding<Double>, presets: [Double] = AppSettings.durationPresets) {
        _hours = hours
        self.presets = presets.isEmpty ? AppSettings.durationPresets : presets
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FlowLayout(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    durationChip(
                        title: "\(AppSettings.formatDurationValue(preset)) h",
                        isSelected: isPresetSelected(preset)
                    ) {
                        isCustomMode = false
                        customText = ""
                        hours = preset
                    }
                }
                durationChip(title: String(localized: "自定义"), isSelected: isCustomMode) {
                    isCustomMode = true
                    if customText.isEmpty {
                        customText = AppSettings.formatDurationValue(hours)
                    }
                }
            }

            if isCustomMode {
                HStack(spacing: 8) {
                    TLTextInput(placeholder: String(localized: "如 1.25"), text: $customText, keyboard: .decimalPad)
                    Text("小时")
                        .font(.subheadline)
                        .foregroundStyle(TLColors.secondaryText)
                }
            }
        }
        .onAppear { syncCustomState() }
        .onChange(of: hours) { _, _ in
            if !isCustomMode && !presets.contains(where: { approxEqual($0, hours) }) {
                isCustomMode = true
                customText = AppSettings.formatDurationValue(hours)
            }
        }
        .onChange(of: customText) { _, newValue in
            guard isCustomMode, let value = AppSettings.parseDuration(newValue) else { return }
            hours = value
        }
    }

    private func durationChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : TLColors.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        TLColors.breezeGradient
                    } else {
                        TLColors.softFillGradient
                    }
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func isPresetSelected(_ preset: Double) -> Bool {
        !isCustomMode && approxEqual(preset, hours)
    }

    private func approxEqual(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) < 0.001
    }

    private func syncCustomState() {
        if presets.contains(where: { approxEqual($0, hours) }) {
            isCustomMode = false
        } else {
            isCustomMode = true
            customText = AppSettings.formatDurationValue(hours)
        }
    }
}
