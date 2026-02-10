import SwiftUI
import TI84Core

/// Menu overlay that appears on top of the display.
struct MenuOverlayView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if let menu = appState.activeMenu {
            VStack(spacing: 0) {
                // Tab bar
                HStack(spacing: 0) {
                    ForEach(Array(menu.definition.tabs.enumerated()), id: \.offset) { idx, tab in
                        Button(action: {
                            appState.activeMenu?.selectedTab = idx
                            appState.activeMenu?.selectedItem = 0
                        }) {
                            Text(tab.name)
                                .font(.system(size: 12, weight: idx == menu.selectedTab ? .bold : .regular, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(idx == menu.selectedTab ? Color.black.opacity(0.2) : Color.clear)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .background(Color(red: 0.68, green: 0.72, blue: 0.62))

                // Items
                let tab = menu.definition.tabs[menu.selectedTab]
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(tab.items.enumerated()), id: \.offset) { idx, item in
                            Button(action: {
                                selectItem(item)
                            }) {
                                HStack {
                                    Text("\(idx + 1):")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(width: 24, alignment: .trailing)

                                    Text(item.label)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.black)

                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                                .background(idx == menu.selectedItem ?
                                           Color.black.opacity(0.15) : Color.clear)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()
            }
            .background(Color(red: 0.78, green: 0.82, blue: 0.72))
            .border(Color.black, width: 1)
        }
    }

    private func selectItem(_ item: MenuItem) {
        if !item.insertText.isEmpty {
            appState.insertText(item.insertText)
        }
        appState.activeMenu = nil
    }
}
