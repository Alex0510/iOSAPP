//
//  ModernDesignSystem.swift
//  现代化设计系统，定义应用的视觉风格和UI组件
//  Created by pxx917144686 UI System on 2025.08.19.
//

import SwiftUI  // SwiftUI框架，用于构建用户界面

// MARK: - 颜色系统
/// 定义应用中使用的所有颜色
extension Color {
    // Fluent 颜色
    static let fluentBlue = Color(red: 0.04, green: 0.36, blue: 0.87)  // Fluent设计蓝色
    static let fluentPurple = Color(red: 0.41, green: 0.18, blue: 0.86)  // Fluent设计紫色
    static let fluentTeal = Color(red: 0.0, green: 0.69, blue: 0.69)  // Fluent设计青绿色
    static let fluentOrange = Color(red: 1.0, green: 0.55, blue: 0.0)  // Fluent设计橙色
    
    // Material 颜色
    static let materialBlue = Color(red: 0.12, green: 0.47, blue: 1.0)  // Material设计蓝色
    static let materialGreen = Color(red: 0.0, green: 0.76, blue: 0.35)  // Material设计绿色，用于成功状态
    static let materialRed = Color(red: 0.96, green: 0.26, blue: 0.21)  // Material设计红色，用于错误/危险状态
    static let materialAmber = Color(red: 1.0, green: 0.76, blue: 0.03)  // Material设计琥珀色，用于警告状态
    static let materialPurple = Color(red: 0.61, green: 0.15, blue: 0.69)  // Material设计紫色
    static let materialPink = Color(red: 0.91, green: 0.12, blue: 0.39)  // Material设计粉色
    static let materialTeal = Color(red: 0.0, green: 0.59, blue: 0.53)  // Material设计青绿色
    static let materialIndigo = Color(red: 0.25, green: 0.32, blue: 0.71)  // Material设计靛蓝色
    static let materialCyan = Color(red: 0.0, green: 0.74, blue: 0.83)  // Material设计青色
    static let materialOrange = Color(red: 1.0, green: 0.34, blue: 0.13)  // Material设计橙色
    static let materialLightBlue = Color(red: 0.01, green: 0.66, blue: 0.96)  // Material设计浅蓝色
    static let materialBrown = Color(red: 0.47, green: 0.33, blue: 0.28)  // Material设计棕色
    static let materialDeepPurple = Color(red: 0.40, green: 0.23, blue: 0.72)  // Material设计深紫色
    static let materialDeepOrange = Color(red: 1.0, green: 0.34, blue: 0.13)  // Material设计深橙色
    
    // 表面颜色 - 使用自定义颜色简化
    static let surfacePrimary = Color(red: 1.0, green: 1.0, blue: 1.0)  // 主要表面颜色，用于背景
    static let surfaceSecondary = Color(red: 0.95, green: 0.95, blue: 0.97)  // 次要表面颜色，用于分隔区域
    static let surfaceTertiary = Color(red: 0.93, green: 0.93, blue: 0.95)  // 第三级表面颜色，用于深度区分
    static let cardBackground = Color(red: 0.98, green: 0.98, blue: 1.0)  // 卡片背景色
    
    // 强调色
    static let primaryAccent = fluentBlue  // 主要强调色，用于重要按钮和交互元素
    static let secondaryAccent = materialGreen  // 次要强调色，用于成功状态和辅助按钮
}

// MARK: - 字体排版系统
/// 定义应用中使用的所有字体样式
extension Font {
    // 展示字体 (大标题)
    static let displayLarge = Font.system(size: 57, weight: .regular, design: .rounded)  // 大标题字体，用于页面主标题
    static let displayMedium = Font.system(size: 45, weight: .regular, design: .rounded)  // 中等标题字体
    static let displaySmall = Font.system(size: 36, weight: .regular, design: .rounded)  // 小标题字体
    
    // 标题字体
    static let headlineLarge = Font.system(size: 32, weight: .medium, design: .rounded)  // 大标题字体，用于重要部分
    static let headlineMedium = Font.system(size: 28, weight: .medium, design: .rounded)  // 中等标题字体
    static let headlineSmall = Font.system(size: 24, weight: .medium, design: .rounded)  // 小标题字体
    
    // 标题字体
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)  // 大标题字体，用于卡片和模块
    static let titleMedium = Font.system(size: 16, weight: .semibold, design: .rounded)  // 中等标题字体
    static let titleSmall = Font.system(size: 14, weight: .semibold, design: .rounded)  // 小标题字体
    
    // 正文字体
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)  // 大正文字体，用于主要内容
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)  // 中正文字体
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)  // 小正文字体，用于辅助信息
    
    // 标签字体
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)  // 大标签字体，用于按钮和控件
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)  // 中标签字体
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)  // 小标签字体，用于小控件和提示
}

// MARK: - 间距系统
/// 定义应用中使用的所有间距尺寸
enum Spacing {
    static let xxs: CGFloat = 2  // 超小间距，用于紧密相邻的元素
    static let xs: CGFloat = 4   // 极小间距，用于小控件内部
    static let sm: CGFloat = 8   // 小间距，用于控件之间
    static let md: CGFloat = 16  // 中等间距，用于内容区块之间
    static let lg: CGFloat = 24  // 大间距，用于主要内容区域
    static let xl: CGFloat = 32  // 极大间距，用于页面分区
    static let xxl: CGFloat = 48 // 超大间距，用于页面顶部和底部
    static let xxxl: CGFloat = 64 // 超极大间距，用于特殊布局
}

// MARK: - 圆角系统
/// 定义应用中使用的所有圆角尺寸
enum CornerRadius {
    static let xs: CGFloat = 4    // 超小圆角，用于小控件
    static let sm: CGFloat = 8    // 小圆角，用于常规控件
    static let md: CGFloat = 12   // 中等圆角，用于卡片
    static let lg: CGFloat = 16   // 大圆角，用于较大区块
    static let xl: CGFloat = 24   // 极大圆角，用于突出显示的元素
    static let xxl: CGFloat = 32  // 超大圆角，用于特殊UI元素
    static let round: CGFloat = 50  // 圆形，用于圆形按钮和头像
}

// MARK: - 阴影系统
/// 定义应用中使用的所有阴影样式
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    static let subtle = ShadowStyle(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)  // 微妙阴影，用于轻微提升效果
    static let soft = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)    // 柔和阴影，用于卡片
    static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)  // 中等阴影，用于突出显示的元素
    static let strong = ShadowStyle(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)    // 强烈阴影，用于强调重要内容

// 提取卡片样式以避免泛型不匹配
/// 卡片样式枚举
enum ModernCardStyle {
    case elevated  // 提升式（带阴影）
    case outlined  // 轮廓式（带边框）
    case filled    // 填充式（纯色背景）
}

// MARK: - 现代卡片组件
/// 现代化卡片组件，支持多种样式和自定义内容
struct ModernCard<Content: View>: View {
    let content: Content  // 卡片内容
    var style: ModernCardStyle = .elevated  // 默认提升式样式
    var padding: CGFloat = Spacing.md       // 默认中等内边距
    
    /// 初始化卡片
    /// - Parameters:
    ///   - style: 卡片样式
    ///   - padding: 内边距
    ///   - content: 卡片内容
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
    
    /// 根据样式获取卡片背景
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

/// 卡片样式修饰器
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
/// 现代化按钮组件，支持多种样式、尺寸和交互效果
struct ModernButton<Label: View>: View {
    let action: () -> Void  // 点击动作回调
    let label: Label  // 按钮标签内容
    var style: ButtonStyle = .primary  // 默认主要样式
    var size: ButtonSize = .medium     // 默认中等尺寸
    var isDisabled: Bool = false         // 是否禁用
    
    /// 按钮样式枚举
    enum ButtonStyle {
        case primary    // 主要按钮（强调色背景）
        case secondary  // 次要按钮（浅色背景）
        case ghost      // 幽灵按钮（透明背景）
        case danger     // 危险按钮（红色背景）
    }
    
    /// 按钮尺寸枚举
    enum ButtonSize {
        case small   // 小尺寸
        case medium  // 中等尺寸
        case large   // 大尺寸
        
        /// 获取按钮高度
        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }
        
        /// 获取按钮内边距
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: Spacing.xs, leading: Spacing.sm, bottom: Spacing.xs, trailing: Spacing.sm)
            case .medium: return EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.sm, trailing: Spacing.md)
            case .large: return EdgeInsets(top: Spacing.md, leading: Spacing.lg, bottom: Spacing.md, trailing: Spacing.lg)
            }
        }
    }
    
    /// 初始化按钮
    /// - Parameters:
    ///   - style: 按钮样式
    ///   - size: 按钮尺寸
    ///   - isDisabled: 是否禁用
    ///   - action: 点击回调
    ///   - label: 按钮标签
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
    
    @State private var isPressed = false  // 按钮按下状态
    
    /// 根据尺寸获取标签字体
    private var labelFont: Font {
        switch size {
        case .small: return .labelSmall
        case .medium: return .labelMedium  
        case .large: return .labelLarge
        }
    }
    
    /// 根据样式获取前景色
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primaryAccent
        case .ghost: return .primary
        case .danger: return .white
        }
    }
    
    /// 根据样式获取背景色
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
/// 浮动操作按钮，通常用于页面的主要操作
struct FloatingActionButton: View {
    let icon: String      // 图标名称
    let action: () -> Void  // 点击动作
    var style: FABStyle = .primary  // 默认主要样式
    var size: FABSize = .regular    // 默认常规尺寸
    
    /// 浮动按钮样式枚举
    enum FABStyle {
        case primary    // 主要样式（强调色背景）
        case secondary  // 次要样式（浅灰色背景）
        case surface    // 表面样式（白色背景）
    }
    
    /// 浮动按钮尺寸枚举
    enum FABSize {
        case small      // 小尺寸
        case regular    // 常规尺寸
        case large      // 大尺寸
        case extended   // 扩展尺寸
        
        /// 获取按钮直径
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
    
    @State private var isPressed = false  // 按钮按下状态
    
    /// 根据尺寸获取图标大小
    private var iconSize: CGFloat {
        switch size {
        case .small: return 18
        case .regular: return 24
        case .large: return 32
        case .extended: return 24
        }
    }
    
    /// 根据样式获取前景色
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primaryAccent
        case .surface: return .primaryAccent
        }
    }
    
    /// 根据样式获取背景色
    private var backgroundColor: Color {
        switch style {
        case .primary: return .primaryAccent
        case .secondary: return .surfaceSecondary
        case .surface: return .surfacePrimary
        }
    }
}

// MARK: - 现代进度指示器
/// 现代化进度指示器，支持线性和圆形两种样式
struct ModernProgressIndicator: View {
    let progress: Double  // 进度值 (0-1)
    var style: ProgressStyle = .linear  // 默认线性样式
    var color: Color = .primaryAccent   // 默认主题色
    
    /// 进度条样式枚举
    enum ProgressStyle {
        case linear     // 线性进度条
        case circular   // 圆形进度条
    }
    
    /// 安全处理进度值，确保在0-1范围内
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
/// 现代化搜索栏组件，支持焦点状态、清除按钮和提交回调
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

/// 预定义的动画效果
extension Animation {
    static let modernSpring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)  // 现代弹簧动画
    static let modernEaseInOut = Animation.easeInOut(duration: 0.3)  // 现代缓入缓出动画
    static let modernBounce = Animation.interpolatingSpring(stiffness: 170, damping: 15)  // 现代弹跳动画
}

/// 自定义视图修饰器扩展
extension View {
    /// 应用现代卡片样式
    func modernCardStyle() -> some View {
        self.modifier(ModernCardStyleModifier())
    }
    
    /// 应用现代玻璃态效果
    func modernGlassEffect() -> some View {
        self.modifier(GlassEffectModifier())
    }
}

/// 现代卡片样式修饰器
struct ModernCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .shadow(color: ShadowStyle.soft.color, radius: ShadowStyle.soft.radius, x: ShadowStyle.soft.x, y: ShadowStyle.soft.y)
    }
}

/// 玻璃态效果修饰器
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
