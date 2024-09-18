import Defaults
import LaunchAtLogin
import Settings
import SwiftUI

struct MainSettingsView: View {
    @Default(.hoverWindowOpenDelay) var hoverWindowOpenDelay
    @Default(.screenCaptureCacheLifespan) var screenCaptureCacheLifespan
    @Default(.showMenuBarIcon) var showMenuBarIcon
    @Default(.tapEquivalentInterval) var tapEquivalentInterval
    @Default(.previewHoverAction) var previewHoverAction
    @Default(.bufferFromDock) var bufferFromDock
    @Default(.sizingMultiplier) var sizingMultiplier
    @Default(.windowPreviewImageScale) var windowPreviewImageScale
    @Default(.fadeOutDuration) var fadeOutDuration
    @Default(.sortWindowsByDate) var sortWindowsByDate

    @Environment(\.openURL) private var openURL

    @State private var thanksPow = 0

    var body: some View {
        let secondsMeasureType = String(localized: "seconds")
        Settings.Container(contentWidth: 620.0, minimumLabelWidth: 230) {
            Settings.Section(title: "", bottomDivider: true) {
                LaunchAtLogin.Toggle(String(localized: "Launch DockDoor at login"))
                Toggle(isOn: $showMenuBarIcon, label: {
                    Text("Show Menu Bar Icon")
                })
                .onChange(of: showMenuBarIcon) { isOn in
                    let appDelegate = NSApplication.shared.delegate as! AppDelegate
                    if isOn {
                        appDelegate.setupMenuBar()
                    } else {
                        appDelegate.removeMenuBar()
                    }
                }
            }

            Settings.Section(title: "Preview Window Open Delay:") {
                SliderPlus(value: $hoverWindowOpenDelay, range: 0 ... 2, step: 0.1, measureType: secondsMeasureType)
            }

            Settings.Section(title: String(localized: "Preview window fade out duration:")) {
                SliderPlus(value: $fadeOutDuration, range: 0 ... 2, step: 0.1, measureType: secondsMeasureType)
            }

            Settings.Section(title: String(localized: "Window buffer:")) {
                SliderPlus(value: $bufferFromDock, range: -200 ... 200, step: 20)
                Text("Adjust this if the preview is misaligned with dock")
                    .settingDescription()
            }

            Settings.Section(title: String(localized: "Window Size:"), verticalAlignment: .top) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(PreviewSize.allCases, id: \.rawValue) { size in
                        SizeView(previewSize: size, selected: sizingMultiplier == CGFloat(size.rawValue))
                            .onTapGesture {
                                sizingMultiplier = CGFloat(size.rawValue)
                            }
                    }
                }
                .onChange(of: sizingMultiplier) { _ in
                    SharedPreviewWindowCoordinator.shared.windowSize = getWindowSize()
                }
            }

            Settings.Section(title: String(localized: "Window Image Cache Lifespan:")) {
                SliderPlus(value: $screenCaptureCacheLifespan, range: 0 ... 60, step: 5, measureType: "seconds")
            }

            Settings.Section(title: String(localized: "Window Image Resolution Scale:")) {
                SliderPlus(value: $screenCaptureCacheLifespan, range: 1 ... 4, step: 1)
                Text("(higher means lower resolution)")
                    .settingDescription()
            }

            Settings.Section(title: String(localized: "Window Image Resolution Scale:")) {
                SliderPlus(value: $screenCaptureCacheLifespan, range: 1 ... 4, step: 1)
                Text("(higher means lower resolution)")
                    .settingDescription()

                Toggle(isOn: $sortWindowsByDate, label: {
                    Text("Sort Window Previews by Date")
                })
            }

            Settings.Section(title: String(localized: "Preview Hover Action:")) {
                Picker(selection: $previewHoverAction) {
                    ForEach(PreviewHoverAction.allCases, id: \.self) { action in
                        Text(action.localizedName).tag(action)
                    }
                } label: { EmptyView() }
                    .pickerStyle(MenuPickerStyle())
                    .scaledToFit()
            }

            Settings.Section(title: String(localized: "Preview Hover Delay:"), bottomDivider: true) {
                SliderPlus(value: $screenCaptureCacheLifespan, range: 0 ... 2, step: 0.1, measureType: "seconds")
                    .disabled(previewHoverAction == .none)
            }

            Settings.Section(title: String(localized: "Want to support development?")) {
                Button {
                    openURL(CommonURLs.donate)
                } label: {
                    Label("Buy me a coffee here!", systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            Settings.Section(title: String(localized: "Help translating!")) {
                Button {
                    openURL(CommonURLs.crowdin)
                } label: {
                    Label("Contribute translation here!", systemImage: "globe.desk.fill")
                }
            }

            Settings.Section(title: String(localized: "Others:"), bottomDivider: true) {
                HStack {
                    Button("Reset All Settings to Defaults") {
                        showResetConfirmation()
                    }
                    Button("Quit DockDoor") {
                        let appDelegate = NSApplication.shared.delegate as! AppDelegate
                        appDelegate.quitApp()
                    }
                }
            }
        }
    }

    private func showResetConfirmation() {
        MessageUtil.showAlert(
            title: String(localized: "Reset to Defaults"),
            message: String(localized: "Are you sure you want to reset all settings to their default values?"),
            actions: [.ok, .cancel]
        ) { action in
            switch action {
            case .ok:
                resetDefaultsToDefaultValues()
            case .cancel:
                // Do nothing
                break
            }
        }
    }
}

enum PreviewSize: Int, CaseIterable {
    case large = 8
    case medium = 6
    case small = 4
    case tiny = 2

    var image: ImageResource {
        switch self {
        case .large: .largePreview
        case .medium: .mediumPreview
        case .small: .smallPreview
        case .tiny: .tinyPreview
        }
    }

    var name: String {
        switch self {
        case .large: "Large"
        case .medium: "Medium"
        case .small: "Small"
        case .tiny: "Tiny"
        }
    }
}

struct SizeView: View, Equatable {
    var previewSize: PreviewSize
    var selected: Bool
    var body: some View {
        VStack(spacing: 5) {
            Image(previewSize.image)
                .resizable()
                .scaledToFit()
                .frame(width: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.blue, lineWidth: selected ? 3 : 0) }

            Text(previewSize.name)
                .font(.system(size: 11))
                .opacity(selected ? 0.75 : 0.5)
        }
        .fixedSize()
    }
}

// struct SizePickerView: View {
//    @Default(.sizingMultiplier) var sizingMultiplier
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Picker("Window Size", selection: $sizingMultiplier) {
//                ForEach(2 ... 10, id: \.self) { size in
//                    Text(getLabel(for: CGFloat(size))).tag(CGFloat(size))
//                }
//            }
//            .scaledToFit()
//            .onChange(of: sizingMultiplier) { _ in
//                SharedPreviewWindowCoordinator.shared.windowSize = getWindowSize()
//            }
//        }
//    }
//
//    private func getLabel(for size: CGFloat) -> String {
//        switch size {
//        case 2:
//            String(localized: "Large", comment: "Window size option")
//        case 3:
//            String(localized: "Default (Medium Large)", comment: "Window size option")
//        case 4:
//            String(localized: "Medium", comment: "Window size option")
//        case 5:
//            String(localized: "Small", comment: "Window size option")
//        case 6:
//            String(localized: "Extra Small", comment: "Window size option")
//        case 7:
//            String(localized: "Extra Extra Small", comment: "Window size option")
//        case 8:
//            String(localized: "What is this? A window for ANTS?", comment: "Window size option")
//        case 9:
//            String(localized: "Subatomic", comment: "Window size option")
//        case 10:
//            String(localized: "Can you even see this?", comment: "Window size option")
//        default:
//            "Unknown Size"
//        }
//    }
// }
