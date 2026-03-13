import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: AppViewModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.08),
                    Color(red: 0.07, green: 0.09, blue: 0.11),
                    Color(red: 0.04, green: 0.11, blue: 0.11),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header
                searchBox
                historyPanel
                footerBar
            }
            .padding(20)
        }
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                searchFocused = true
            }
        }
        .onExitCommand {
            viewModel.closePanel()
        }
    }

    private var historyPanel: some View {
        Group {
            if viewModel.filteredItems.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.filteredItems) { item in
                                ClipboardRowView(
                                    item: item,
                                    isSelected: item.id == viewModel.selectedItemID,
                                    onCopy: {
                                        viewModel.select(item)
                                        viewModel.copy(item)
                                    },
                                    onTogglePinned: { viewModel.togglePinned(item) },
                                    onDelete: { viewModel.delete(item) }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.trailing, 4)
                        .padding(.bottom, 4)
                    }
                    .onAppear {
                        guard let selectedItemID = viewModel.selectedItemID else {
                            return
                        }
                        proxy.scrollTo(selectedItemID, anchor: .top)
                    }
                    .onChange(of: viewModel.selectedItemID) { _, selectedItemID in
                        guard let selectedItemID else {
                            return
                        }
                        withAnimation(.easeInOut(duration: 0.12)) {
                            proxy.scrollTo(selectedItemID, anchor: .center)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(panelBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RA/NPaste")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .tracking(1.0)
                        .foregroundStyle(Color(red: 0.80, green: 1.0, blue: 0.90))

                    Text("浮层命令面板")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.64))
                }

                Spacer()

                HStack(spacing: 8) {
                    chip(title: "HOTKEY", value: viewModel.shortcutLabel)
                    chip(title: "ITEMS", value: "\(viewModel.totalCount)")
                }
            }
        }
    }

    private var searchBox: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(red: 0.66, green: 1.0, blue: 0.85))

            TextField("搜索文本历史", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .focused($searchFocused)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.46, green: 1.0, blue: 0.80).opacity(0.28), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Color(red: 0.66, green: 1.0, blue: 0.85))

            Text("没有匹配的历史")
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            Text("复制一些文本，或者修改搜索关键词。")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            Text(viewModel.isMonitoringPaused ? "监听已暂停" : "监听运行中")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(viewModel.isMonitoringPaused ? Color(red: 1.0, green: 0.74, blue: 0.42) : Color(red: 0.68, green: 1.0, blue: 0.86))

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 3, height: 3)

            Text("ESC 关闭")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.46))

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 3, height: 3)

            Text("↑ ↓ 切换 · Enter 粘贴")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.46))

            Spacer()

            Text("管理动作请在状态栏菜单中执行")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
        }
        .padding(.horizontal, 4)
    }

    private func chip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.72, green: 1.0, blue: 0.88))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.28), radius: 30, x: 0, y: 20)
    }
}
