import SwiftUI

struct ItemIconView: View {
    let iconName: String
    let itemType: ItemType
    
    private var isEmoji: Bool {
        guard let first = iconName.first else { return false }
        return first.isEmoji && !first.isASCII
    }
    
    var body: some View {
        Group {
            if isEmoji {
                Text(iconName)
                    .font(.title3)
            } else {
                Image(systemName: iconName.isEmpty ? "doc.text.fill" : iconName)
                    .font(.body)
                    .foregroundStyle(color(for: itemType))
            }
        }
        .frame(width: 28, height: 28)
    }
    
    private func color(for type: ItemType) -> Color {
        switch type {
        case .paycheck: return .green
        case .bill: return .red
        case .subscription: return .purple
        }
    }
}