//
//  ModernDesignSystem.swift
//  Created by pxx917144686 UI System on 2025.08.19.
//

import SwiftUI

// MARK: - 颜色系统
extension Color {
    // Fluent 设计语言颜色
    static let fluentBlue = Color(red: 0.04, green: 0.36, blue: 0.87)  // Fluent 蓝色
    static let fluentPurple = Color(red: 0.41, green: 0.18, blue: 0.86)  // Fluent 紫色
    static let fluentTeal = Color(red: 0.0, green: 0.69, blue: 0.69)  // Fluent 蓝绿色
    static let fluentOrange = Color(red: 1.0, green: 0.55, blue: 0.0)  // Fluent 橙色
    
    // Material 设计语言颜色
    static let materialBlue = Color(red: 0.12, green: 0.47, blue: 1.0)  // Material 蓝色
    static let materialGreen = Color(red: 0.0, green: 0.76, blue: 0.35)  // Material 绿色
    static let materialRed = Color(red: 0.96, green: 0.26, blue: 0.21)  // Material 红色
    static let materialAmber = Color(red: 1.0, green: 0.76, blue: 0.03)  // Material 琥珀色
    static let materialPurple = Color(red: 0.61, green: 0.15, blue: 0.69)  // Material 紫色
    static let materialPink = Color(red: 0.91, green: 0.12, blue: 0.39)  // Material 粉色
    static let materialTeal = Color(red: 0.0, green: 0.59, blue: 0.53)  // Material 蓝绿色
    static let materialIndigo = Color(red: 0.25, green: 0.32, blue: 0.71)  // Material 靛蓝色
    static let materialCyan = Color(red: 0.0, green: 0.74, blue: 0.83)  // Material 青色
    static let materialOrange = Color(red: 1.0, green: 0.34, blue: 0.13)  // Material 橙色
    static let materialLightBlue = Color(red: 0.01, green: 0.66, blue: 0.96)  // Material 浅蓝色
    static let materialBrown = Color(red: 0.47, green: 0.33, blue: 0.28)  // Material 棕色
    static let materialDeepPurple = Color(red: 0.40, green: 0.23, blue: 0.72)  // Material 深紫色
    static let materialDeepOrange = Color(red: 1.0, green: 0.34, blue: 0.13)  // Material 深橙色
    
    // 表面颜色 - 用于界面背景和卡片
    static let surfacePrimary = Color(red: 1.0, green: 1.0, blue: 1.0)  // 主要表面颜色
    static let surfaceSecondary = Color(red: 0.95, green: 0.95, blue: 0.97)  // 次要表面颜色
    static let surfaceTertiary = Color(red: 0.93, green: 0.93, blue: 0.95)  // 第三级表面颜色
    static let cardBackground = Color(red: 0.98, green: 0.98, blue: 1.0)  // 卡片背景颜色
    
    // 强调色 - 用于重要元素和交互反馈
    static let primaryAccent = fluentBlue  // 主要强调色
    static let secondaryAccent = materialGreen  // 次要强调色
}

// MARK: - 字体排版系统
extension Font {
    // 展示字体 - 用于大标题
    static let displayLarge = Font.system(size: 57, weight: .regular, design: .rounded)  // 大号展示字体
    static let displayMedium = Font.system(size: 45, weight: .regular, design: .rounded)  // 中号展示字体
    static let displaySmall = Font.system(size: 36, weight: .regular, design: .rounded)  // 小号展示字体
    
    // 大标题字体
    static let headlineLarge = Font.system(size: 32, weight: .medium, design: .rounded)  // 大号大标题字体
    static let headlineMedium = Font.system(size: 28, weight: .medium, design: .rounded)  // 中号大标题字体
    static let headlineSmall = Font.system(size: 24, weight: .medium, design: .rounded)  // 小号大标题字体
    
    // 标题字体
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)  // 大号标题字体
    static let titleMedium = Font.system(size: 16, weight: .semibold, design: .rounded)  // 中号标题字体
    static let titleSmall = Font.system(size: 14, weight: .semibold, design: .rounded)  // 小号标题字体
    
    // 正文字体
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)  // 大号正文字体
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)  // 中号正文字体
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)  // 小号正文字体
    
    // 标签字体 - 用于按钮和小文本
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)  // 大号标签字体
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)  // 中号标签字体
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)  // 小号标签字体
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
        // 将内容添加内边距、背景色、圆角，并应用卡片样式修饰器
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
                Color.cardBackground  // 提升式卡片使用卡片背景色
            case .outlined:
                Color.surfacePrimary  // 轮廓式卡片使用主要表面颜色
            case .filled:
                Color.surfaceSecondary  // 填充式卡片使用次要表面颜色
            }
        }
    }
}

struct CardStyleModifier: ViewModifier {
    let style: ModernCardStyle
    
    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            // 提升式卡片添加中等阴影效果
            content
                .shadow(color: ShadowStyle.medium.color, radius: ShadowStyle.medium.radius, x: ShadowStyle.medium.x, y: ShadowStyle.medium.y)
        case .outlined:
            // 轮廓式卡片添加灰色半透明边框
            content
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        case .filled:
            // 填充式卡片不做额外修饰
            content
        }
    }
}

// MARK: - 现代按钮组件
struct ModernButton<Label: View>: View {
    let action: () -> Void  // 按钮点击动作
    let label: Label  // 按钮标签
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
        // 创建按钮，点击时执行 action
        Button(action: action) {
            label
                .font(labelFont)  // 设置标签字体
                .foregroundColor(foregroundColor)  // 设置前景色
                .padding(size.padding)  // 设置内边距
                .frame(minHeight: size.height)  // 设置最小高度
                .frame(maxWidth: .infinity)  // 最大宽度占满父视图
                .background(backgroundColor)  // 设置背景色
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))  // 设置圆角
                .scaleEffect(isPressed ? 0.98 : 1.0)  // 点击时缩小效果
                .animation(.easeInOut(duration: 0.1), value: isPressed)  // 动画效果
        }
        .disabled(isDisabled)  // 禁用按钮
        .opacity(isDisabled ? 0.6 : 1.0)  // 禁用时半透明
    }
    
    @State private var isPressed = false  // 按钮是否被按下的状态
    
    private var labelFont: Font {
        switch size {
        case .small: return .labelSmall  // 小尺寸按钮使用小号标签字体
        case .medium: return .labelMedium  // 中等尺寸按钮使用中号标签字体
        case .large: return .labelLarge  // 大尺寸按钮使用大号标签字体
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white  // 主要按钮白色文字
        case .secondary: return .primaryAccent  // 次要按钮使用主要强调色文字
        case .ghost: return .primary  // 幽灵按钮使用主色文字
        case .danger: return .white  // 危险按钮白色文字
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .primaryAccent  // 主要按钮使用主要强调色背景
        case .secondary: return .primaryAccent.opacity(0.1)  // 次要按钮使用主要强调色半透明背景
        case .ghost: return .clear  // 幽灵按钮透明背景
        case .danger: return .materialRed  // 危险按钮使用 Material 红色背景
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
        // 创建按钮，点击时执行 action
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))  // 设置图标字体大小和粗细
                .foregroundColor(foregroundColor)  // 设置图标颜色
                .frame(width: size.diameter, height: size.diameter)  // 设置按钮尺寸
                .background(backgroundColor)  // 设置背景色
                .clipShape(Circle())  // 设置为圆形
                .shadow(color: ShadowStyle.medium.color, radius: ShadowStyle.medium.radius, x: ShadowStyle.medium.x, y: ShadowStyle.medium.y)  // 添加中等阴影
                .scaleEffect(isPressed ? 0.95 : 1.0)  // 点击时缩小效果
                .animation(.spring(response: 0.3), value: isPressed)  // 弹簧动画效果
        }
        .onTapGesture {
            // 点击时改变按钮状态并在 0.1 秒后恢复
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
    
    @State private var isPressed = false  // 按钮是否被按下的状态
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 18  // 小尺寸按钮图标大小 18
        case .regular: return 24  // 常规尺寸按钮图标大小 24
        case .large: return 32  // 大尺寸按钮图标大小 32
        case .extended: return 24  // 扩展尺寸按钮图标大小 24
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white  // 主要样式白色图标
        case .secondary: return .primaryAccent  // 次要样式使用主要强调色图标
        case .surface: return .primaryAccent  // 表面样式使用主要强调色图标
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .primaryAccent  // 主要样式使用主要强调色背景
        case .secondary: return .surfaceSecondary  // 次要样式使用次要表面颜色背景
        case .surface: return .surfacePrimary  // 表面样式使用主要表面颜色背景
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
            // 线性进度条，垂直放大 2 倍
            ProgressView(value: safeProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 2.0)
        case .circular:
            // 圆形进度条
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
        // 水平排列搜索栏组件
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)  // 设置放大镜图标颜色
                .font(.system(size: 16, weight: .medium))  // 设置图标字体大小和粗细
            
            TextField(placeholder, text: $text)
                .focused($isFocused)  // 绑定焦点状态
                .font(.bodyMedium)  // 设置输入框字体
                .onSubmit(onSubmit)  // 提交时执行回调
            
            if !text.isEmpty {
                // 当输入框有内容时显示清除按钮
                Button {
                    text = ""  // 点击清除输入框内容
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)  // 设置清除图标颜色
                        .font(.system(size: 16))  // 设置图标字体大小
                }
            }
        }
        .padding(.horizontal, Spacing.md)  // 设置水平内边距
        .padding(.vertical, Spacing.sm)  // 设置垂直内边距
        .background(Color.surfaceSecondary)  // 设置背景色
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))  // 设置圆角
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(isFocused ? Color.primaryAccent : Color.clear, lineWidth: 2)  // 聚焦时显示主要强调色边框
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)  // 聚焦状态变化时的动画效果
    }
}

// MARK: - 动画预设
extension Animation {
    static let modernSpring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)  // 现代弹簧动画
    static let modernEaseInOut = Animation.easeInOut(duration: 0.3)  // 现代缓入缓出动画
    static let modernBounce = Animation.interpolatingSpring(stiffness: 170, damping: 15)  // 现代弹跳动画
}

// MARK: - 视图修饰符
extension View {
    func modernCardStyle() -> some View {
        self.modifier(ModernCardStyleModifier())  // 应用现代卡片样式修饰器
    }
    
    func modernGlassEffect() -> some View {
        self.modifier(GlassEffectModifier())  // 应用现代玻璃效果修饰器
    }
}

struct ModernCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))  // 设置超薄材质背景和圆角
            .shadow(color: ShadowStyle.soft.color, radius: ShadowStyle.soft.radius, x: ShadowStyle.soft.x, y: ShadowStyle.soft.y)  // 添加柔和阴影
    }
}

struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: CornerRadius.lg))  // 设置半透明超薄材质背景和圆角
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(.white.opacity(0.2), lineWidth: 1)  // 添加白色半透明边框
            )
    }
}
