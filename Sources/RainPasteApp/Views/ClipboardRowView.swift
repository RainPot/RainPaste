import SwiftUI

struct ClipboardRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onCopy: () -> Void
    let onTogglePinned: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        if item.isPinned {
                            Text("PINNED")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.52, green: 1.0, blue: 0.82).opacity(0.16))
                                )
                                .foregroundStyle(Color(red: 0.68, green: 1.0, blue: 0.86))
                        }

                        Text(Self.dateFormatter.string(from: item.createdAt))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    Text(item.content)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(3)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 12)

                HStack(spacing: 10) {
                    iconButton(
                        systemImage: "doc.on.doc",
                        tint: Color(red: 0.46, green: 1.0, blue: 0.80),
                        action: onCopy
                    )
                    iconButton(
                        systemImage: item.isPinned ? "pin.slash" : "pin",
                        tint: Color(red: 0.98, green: 0.80, blue: 0.40),
                        action: onTogglePinned
                    )
                    iconButton(
                        systemImage: "trash",
                        tint: Color(red: 1.0, green: 0.48, blue: 0.38),
                        action: onDelete
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? Color(red: 0.20, green: 0.36, blue: 0.31).opacity(0.55) : Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected
                        ? Color(red: 0.58, green: 1.0, blue: 0.84).opacity(0.62)
                        : Color.white.opacity(0.08),
                    lineWidth: isSelected ? 1.4 : 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture(perform: onCopy)
    }

    private func iconButton(systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.32), lineWidth: 1)
        )
        .foregroundStyle(tint)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter
    }()
}
