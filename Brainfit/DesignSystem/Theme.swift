import SwiftUI

public enum Theme {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 40
    }

    public enum Radius {
        public static let card: CGFloat = 16
        public static let button: CGFloat = 12
    }

    public enum FontStyle {
        public static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
        public static let title = Font.title.weight(.semibold)
        public static let body = Font.body
        public static let caption = Font.caption
    }
}

public extension ShapeStyle where Self == Color {
    static var brainfitBackground: Color { Color(.systemBackground) }
    static var brainfitCard: Color { Color(.secondarySystemBackground) }
    static var brainfitMutedText: Color { Color(.secondaryLabel) }
}
