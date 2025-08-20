//
//  ModernDesignSystem.swift
//  Created by pxx917144686 UI System on 2025.08.19.
//

import SwiftUI

// MARK: - 颜色系统
extension Color {
    // Fluent 设计语言颜色
    static let fluentBlue = Color(red: 0.04, green: 0.36, blue: 0.87)
    static let fluentPurple = Color(red: 0.41, green: 0.18, blue: 0.86)
    static let fluentTeal = Color(red: 0.0, green: 0.69, blue: 0.69)
    static let fluentOrange = Color(red: 1.0, green: 0.55, blue: 0.0)
    
    // Material 设计语言颜色
    static let materialBlue = Color(red: 0.12, green: 0.47, blue: 1.0)
    static let materialGreen = Color(red: 0.0, green: 0.76, blue: 0.35)
    static let materialRed = Color(red: 0.96, green: 0.26, blue: 0.21)
    static let materialAmber = Color(red: 1.0, green: 0.76, blue: 0.03)
    static let materialPurple = Color(red: 0.61, green: 0.15, blue: 0.69)
    static let materialPink = Color(red: 0.91, green: 0.12, blue: 0.39)
    static let materialTeal = Color(red: 0.0, green: 0.59, blue: 0.53)
    static let materialIndigo = Color(red: 0.25, green: 0.32, blue: 0.71)
    static let materialCyan = Color(red: 0.0, green: 0.74, blue: 0.83)
    static let materialOrange = Color(red: 1.0, green: 0.34, blue: 0.13)
    static let materialLightBlue = Color(red: 0.01, green: 0.66, blue: 0.96)
    static let materialBrown = Color(red: 0.47, green: 0.33, blue: 0.28)
    static let materialDeepPurple = Color(red: 0.40, green: 0.23, blue: 0.72)
    static let materialDeepOrange = Color(red: 1.0, green: 0.34, blue: 0.13)
    
    // 表面颜色 - 用于界面背景和卡片
    static let surfacePrimary = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let surfaceSecondary = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let surfaceTertiary = Color(red: 0.93, green: 0.93, blue: 0.95)
    static let cardBackground = Color(red: 0.98, green: 0.98, blue: 1.0)
    
    // 强调色 - 用于重要元素和交互反馈
    static let primaryAccent = fluentBlue
    static let secondaryAccent = materialGreen
}

// MARK: - 字体排版系统
extension Font {
    // 展示字体 - 用于大标题
    static let displayLarge = Font.system(size: 57, weight: .regular, design: .rounded)
    static let displayMedium = Font.system(size: 45, weight: .regular, design: .rounded)
    static let displaySmall = Font.system(size: 36, weight: .regular, design: .rounded)
    
    // 大标题字体
    static let headlineLarge = Font.system(size: 32, weight: .medium, design: .rounded)
    static let headlineMedium = Font.system(size: 28, weight: .medium, design: .rounded)
    static let headlineSmall = Font.system(size: 24, weight: .medium, design: .rounded)
    
    // 标题字体
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let titleMedium = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let titleSmall = Font.system(size: 14, weight: .semibold, design: .rounded)
    
    // 正文字体
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // 标签字体 - 用于按钮和小文本
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
}

// MARK: - 间距系统
enum Spacing {
    static let xxs: CGFloat = 2  // 超小间距
    static let xs: CGFloat = 4   // 极小间距
    static let sm: CGFloat = 8   // 小间距
    static let md: CGFloat = 16  // 中等间距
    static let lg: CGFloat = 24  // 大间距
    static let xl: CGFloat = 32  // 极大间距
    static let xxl: CGFloat = 48 // 超大间距
    static let xxxl: CGFloat = 64 // 超极大间距
}

// MARK: - 圆角系统
enum CornerRadius {
    static let xs: CGFloat = 4    // 超小圆角
    static let sm: CGFloat = 8    // 小圆角
    static let md: CGFloat = 12   // 中等圆角
    static let lg: CGFloat = 16   // 大圆角
    static let xl: CGFloat = 24   // 极大圆角
    static let xxl: CGFloat = 32  // 超大圆角
    static let round: CGFloat = 50  // 圆形
}

// MARK: - 阴影系统
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    static let subtle = ShadowStyle(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)  // 微妙阴影
    static let soft = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)    // 柔和阴影
    static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)  // 中等阴影
    static let strong = ShadowStyle(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)    // 强烈阴影
}

// 提取卡片样式以避免泛型不匹配
enum ModernCardStyle {
    case elevated  // 提升式 - 带阴影的卡片
    case outlined  // 轮廓式 - 带边框的卡片
    case filled    // 填充式 - 带背景色的卡片
}

// MARK: - 现代卡片组件
struct ModernCard<Content: View>: View {
    let content: Content
    var style: ModernCardStyle = .elevated  // 默认提升式样式
    var padding: CGFloat = Spacing.md       // 默认中等内边距
    
    init(style: ModernCardStyle = .elevated, padding: CGFloat = Spacing.md, @ViewBuilder content: () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .modifier(CardStyleModifier(style: style))
    }
    
    private var cardBackground: some View {
        Group {
            switch style {
            case .elevated:
                Color.cardBackground
            case .outlined:
                Color.surfacePrimary
            case .filled:
                Color.surfaceSecondary
            }
        }
    }
}

struct CardStyleModifier: ViewModifier {
    let style: ModernCardStyle
    
    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content
                .shadow(color: ShadowStyle.medium.color, radius: ShadowStyle.medium.radius, x: ShadowStyle.medium.x, y: ShadowStyle.medium.y)
        case .outlined:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        case .filled:
            content
        }
    }
}

// MARK: - 现代按钮组件
struct ModernButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    var style: ButtonStyle = .primary  // 默认主要样式
    var size: ButtonSize = .medium     // 默认中等尺寸
    var isDisabled: Bool = false         // 是否禁用
    
    enum ButtonStyle {
        case primary    // 主要按钮 - 用于主要操作
        case secondary  // 次要按钮 - 用于次要操作
        case ghost      // 幽灵按钮 - 透明背景
        case danger     // 危险按钮 - 用于危险操作
    }
    
    enum ButtonSize {
        case small   // 小尺寸按钮
        case medium  // 中等尺寸按钮
        case large   // 大尺寸按钮
        
        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: Spacing.xs, leading: Spacing.sm, bottom: Spacing.xs, trailing: Spacing.sm)
            case .medium: return EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.sm, trailing: Spacing.md)
            case .large: return EdgeInsets(top: Spacing.md, leading: Spacing.lg, bottom: Spacing.md, trailing: Spacing.lg)
            }
        }
    }
    
    init(style: ButtonStyle = .primary, size: ButtonSize = .medium, isDisabled: Bool = false, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.action = action
        self.label = label()
    }
    
    var body: some View {
        Button(action: action) {
            label
                .font(labelFont)
                .foregroundColor(foregroundColor)
                .padding(size.padding)
                .frame(minHeight: size.height)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    
    @State private var isPressed = false
    
    private var labelFont: Font {
        switch size {
        case .small: return .labelSmall
        case .medium: return .labelMedium  
        case .large: return .labelLarge
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primaryAccent
        case .ghost: return .primary
        case .danger: return .white
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .primaryAccent
        case .secondary: return .primaryAccent.opacity(0.1)
        case .ghost: return .clear
        case .danger: return .materialRed
        }
    }
}

// MARK: - 浮动操作按钮
struct FloatingActionButton: View {
    let icon: String      // 图标名称
    let action: () -> Void  // 点击动作
    var style: FABStyle = .primary  // 默认主要样式
    var size: FABSize = .regular    // 默认常规尺寸
    
    enum FABStyle {
        case primary    // 主要样式
        case secondary  // 次要样式
        case surface    // 表面样式
    }
    
    enum FABSize {
        case small      // 小尺寸
        case regular    // 常规尺寸
        case large      // 大尺寸
        case extended   // 扩展尺寸
        
        var diameter: CGFloat {
            switch self {
            case .small: return 40
            case .regular: return 56
            case .large: return 96
            case .extended: return 56
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size.diameter, height: size.diameter)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(color: ShadowStyle.medium.color, radius: ShadowStyle.medium.radius, x: ShadowStyle.medium.x, y: ShadowStyle.medium.y)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3), value: isPressed)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
    
    @State private var isPressed = false
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 18
        case .regular: return 24
        case .large: return 32
        case .extended: return 24
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primaryAccent
        case .surface: return .primaryAccent
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .primaryAccent
        case .secondary: return .surfaceSecondary
        case .surface: return .surfacePrimary
        }
    }
}

// MARK: - 现代进度指示器
struct ModernProgressIndicator: View {
    let progress: Double  // 进度值 (0-1)
    var style: ProgressStyle = .linear  // 默认线性样式
    var color: Color = .primaryAccent   // 默认主题色
    
    enum ProgressStyle {
        case linear     // 线性进度条
        case circular   // 圆形进度条
    }
    
    private var safeProgress: Double {
        // 检查并处理NaN、无穷大或负值
        if progress.isNaN || progress.isInfinite || progress < 0 {
            return 0.0
        }
        // 确保进度值在0到1之间
        return min(max(progress, 0.0), 1.0)
    }
    
    var body: some View {
        switch style {
        case .linear:
            ProgressView(value: safeProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 2.0)
        case .circular:
            ProgressView(value: safeProgress)
                .progressViewStyle(CircularProgressViewStyle(tint: color))
        }
    }
}

// MARK: - 现代搜索栏
struct ModernSearchBar: View {
    @Binding var text: String  // 搜索文本绑定
    @FocusState private var isFocused: Bool  // 焦点状态
    var placeholder: String = "搜索"  // 占位符文本
    var onSubmit: () -> Void = {}  // 提交回调
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .font(.bodyMedium)
                .onSubmit(onSubmit)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(isFocused ? Color.primaryAccent : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - 动画预设
extension Animation {
    static let modernSpring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)
    static let modernEaseInOut = Animation.easeInOut(duration: 0.3)
    static let modernBounce = Animation.interpolatingSpring(stiffness: 170, damping: 15)
}

// MARK: - 视图修饰符
extension View {
    func modernCardStyle() -> some View {
        self.modifier(ModernCardStyleModifier())
    }
    
    func modernGlassEffect() -> some View {
        self.modifier(GlassEffectModifier())
    }
}

struct ModernCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .shadow(color: ShadowStyle.soft.color, radius: ShadowStyle.soft.radius, x: ShadowStyle.soft.x, y: ShadowStyle.soft.y)
    }
}

struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}
