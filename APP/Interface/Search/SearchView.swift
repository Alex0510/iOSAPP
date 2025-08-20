//
//  SearchView.swift
//  Created by pxx917144686 on 2025/08/19.
//

// 导入 Apple 相关包
import ApplePackage
// 导入 Kingfisher 库，用于图片加载
import Kingfisher
// 导入 SwiftUI 框架
import SwiftUI

// 定义搜索视图结构体，遵循 View 协议
struct SearchView: View {
    // 从 AppStorage 中读取或存储搜索关键词
    @AppStorage("searchKey") var searchKey = ""
    // 从 AppStorage 中读取或存储搜索地区
    @AppStorage("searchRegion") var searchRegion = "US"
    // 从 AppStorage 中读取或存储搜索历史数据
    @AppStorage("searchHistory") var searchHistoryData = Data()
    // 控制搜索关键词输入框的焦点状态
    @FocusState var searchKeyFocused
    // 记录当前搜索类型
    @State var searchType = EntityType.iPhone
    // 标记是否正在搜索
    @State var searching = false
    
    // 静态属性：国家代码到国家名称的映射
    static let countryCodeMap: [String: String] = [
        "AE": "United Arab Emirates", "AG": "Antigua and Barbuda", "AI": "Anguilla", "AL": "Albania", "AM": "Armenia",
        "AO": "Angola", "AR": "Argentina", "AT": "Austria", "AU": "Australia", "AZ": "Azerbaijan",
        "BB": "Barbados", "BD": "Bangladesh", "BE": "Belgium", "BG": "Bulgaria", "BH": "Bahrain",
        "BM": "Bermuda", "BN": "Brunei", "BO": "Bolivia", "BR": "Brazil", "BS": "Bahamas",
        "BW": "Botswana", "BY": "Belarus", "BZ": "Belize", "CA": "Canada", "CH": "Switzerland",
        "CI": "Côte d'Ivoire", "CL": "Chile", "CN": "China", "CO": "Colombia", "CR": "Costa Rica",
        "CY": "Cyprus", "CZ": "Czech Republic", "DE": "Germany", "DK": "Denmark", "DM": "Dominica",
        "DO": "Dominican Republic", "DZ": "Algeria", "EC": "Ecuador", "EE": "Estonia", "EG": "Egypt",
        "ES": "Spain", "FI": "Finland", "FR": "France", "GB": "United Kingdom", "GD": "Grenada",
        "GE": "Georgia", "GH": "Ghana", "GR": "Greece", "GT": "Guatemala", "GY": "Guyana",
        "HK": "Hong Kong", "HN": "Honduras", "HR": "Croatia", "HU": "Hungary", "ID": "Indonesia",
        "IE": "Ireland", "IL": "Israel", "IN": "India", "IS": "Iceland", "IT": "Italy",
        "JM": "Jamaica", "JO": "Jordan", "JP": "Japan", "KE": "Kenya", "KN": "Saint Kitts and Nevis",
        "KR": "South Korea", "KW": "Kuwait", "KY": "Cayman Islands", "KZ": "Kazakhstan", "LB": "Lebanon",
        "LC": "Saint Lucia", "LI": "Liechtenstein", "LK": "Sri Lanka", "LT": "Lithuania", "LU": "Luxembourg",
        "LV": "Latvia", "MD": "Moldova", "MG": "Madagascar", "MK": "North Macedonia", "ML": "Mali",
        "MN": "Mongolia", "MO": "Macao", "MS": "Montserrat", "MT": "Malta", "MU": "Mauritius",
        "MV": "Maldives", "MX": "Mexico", "MY": "Malaysia", "NE": "Niger", "NG": "Nigeria",
        "NI": "Nicaragua", "NL": "Netherlands", "NO": "Norway", "NP": "Nepal", "NZ": "New Zealand",
        "OM": "Oman", "PA": "Panama", "PE": "Peru", "PH": "Philippines", "PK": "Pakistan",
        "PL": "Poland", "PT": "Portugal", "PY": "Paraguay", "QA": "Qatar", "RO": "Romania",
        "RS": "Serbia", "RU": "Russia", "SA": "Saudi Arabia", "SE": "Sweden", "SG": "Singapore",
        "SI": "Slovenia", "SK": "Slovakia", "SN": "Senegal", "SR": "Suriname", "SV": "El Salvador",
        "TC": "Turks and Caicos", "TH": "Thailand", "TN": "Tunisia", "TR": "Turkey", "TT": "Trinidad and Tobago",
        "TW": "Taiwan", "TZ": "Tanzania", "UA": "Ukraine", "UG": "Uganda", "US": "United States",
        "UY": "Uruguay", "UZ": "Uzbekistan", "VC": "Saint Vincent and the Grenadines", "VE": "Venezuela",
        "VG": "British Virgin Islands", "VN": "Vietnam", "YE": "Yemen", "ZA": "South Africa"
    ]
    
    // 静态属性：国家代码到商店前台代码的映射
    static let storeFrontCodeMap = [
        "AE": "143481", "AG": "143540", "AI": "143538", "AL": "143575", "AM": "143524",
        "AO": "143564", "AR": "143505", "AT": "143445", "AU": "143460", "AZ": "143568",
        "BB": "143541", "BD": "143490", "BE": "143446", "BG": "143526", "BH": "143559",
        "BM": "143542", "BN": "143560", "BO": "143556", "BR": "143503", "BS": "143539",
        "BW": "143525", "BY": "143565", "BZ": "143555", "CA": "143455", "CH": "143459",
        "CI": "143527", "CL": "143483", "CN": "143465", "CO": "143501", "CR": "143495",
        "CY": "143557", "CZ": "143489", "DE": "143443", "DK": "143458", "DM": "143545",
        "DO": "143508", "DZ": "143563", "EC": "143509", "EE": "143518", "EG": "143516",
        "ES": "143454", "FI": "143447", "FR": "143442", "GB": "143444", "GD": "143546",
        "GE": "143615", "GH": "143573", "GR": "143448", "GT": "143504", "GY": "143553",
        "HK": "143463", "HN": "143510", "HR": "143494", "HU": "143482", "ID": "143476",
        "IE": "143449", "IL": "143491", "IN": "143467", "IS": "143558", "IT": "143450",
        "JM": "143511", "JO": "143528", "JP": "143462", "KE": "143529", "KN": "143548",
        "KR": "143466", "KW": "143493", "KY": "143544", "KZ": "143517", "LB": "143497",
        "LC": "143549", "LI": "143522", "LK": "143486", "LT": "143520", "LU": "143451",
        "LV": "143519", "MD": "143523", "MG": "143531", "MK": "143530", "ML": "143532",
        "MN": "143592", "MO": "143515", "MS": "143547", "MT": "143521", "MU": "143533",
        "MV": "143488", "MX": "143468", "MY": "143473", "NE": "143534", "NG": "143561",
        "NI": "143512", "NL": "143452", "NO": "143457", "NP": "143484", "NZ": "143461",
        "OM": "143562", "PA": "143485", "PE": "143507", "PH": "143474", "PK": "143477",
        "PL": "143478", "PT": "143453", "PY": "143513", "QA": "143498", "RO": "143487",
        "RS": "143500", "RU": "143469", "SA": "143479", "SE": "143456", "SG": "143464",
        "SI": "143499", "SK": "143496", "SN": "143535", "SR": "143554", "SV": "143506",
        "TC": "143552", "TH": "143475", "TN": "143536", "TR": "143480", "TT": "143551",
        "TW": "143470", "TZ": "143572", "UA": "143492", "UG": "143537", "US": "143441",
        "UY": "143514", "UZ": "143566", "VC": "143550", "VE": "143502", "VG": "143543",
        "VN": "143471", "YE": "143571", "ZA": "143472"
    ]
    
    // 存储按字母顺序排序的地区代码数组
    let regionKeys = Array(SearchView.storeFrontCodeMap.keys.sorted())

    // 当前搜索输入内容
    @State var searchInput: String = ""
    // 存储搜索结果
    @State var searchResult: [iTunesResponse.iTunesArchive] = []
    // 当前搜索结果的页码
    @State private var currentPage = 1
    // 标记是否正在加载更多结果
    @State private var isLoadingMore = false
    // 每页显示的结果数量
    private let pageSize = 20
    // 存储搜索历史记录
    @State var searchHistory: [String] = []
    // 标记是否显示搜索历史
    @State var showSearchHistory = false
    // 当前的排序选项
    @State var sortOption: SortOption = .relevance
    // 标记是否显示筛选器
    @State var showFilters = false
    // 标记是否显示地区选择器
    @State var showRegionPicker = false
    // 标记是否处于悬停状态
    @State var isHovered = false

    // 状态对象，存储 AppStore 实例
    @StateObject var vm = AppStore.this

    // 标记是否对搜索头部区域进行动画
    @State private var animateHeader = false
    // 标记是否对搜索栏进行动画
    @State private var animateSearchBar = false
    // 标记是否对搜索结果区域进行动画
    @State private var animateResults = false
    // 当前选中的搜索分类
    @State private var selectedCategory: SearchCategory = .all
    // 标记是否显示高级筛选器
    @State private var showAdvancedFilters = false
    // 网格视图的列数
    @State private var gridColumns = 2
    // 当前的视图模式
    @State private var viewMode: ViewMode = .grid
    
    // 定义搜索分类枚举
    enum SearchCategory: String, CaseIterable {
        case all = "全部"
        case apps = "应用"
        case games = "游戏"
        case productivity = "效率"
        case entertainment = "娱乐"
        
        // 获取每个分类对应的图标名称
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .apps: return "app.fill"
            case .games: return "gamecontroller.fill"
            case .productivity: return "briefcase.fill"
            case .entertainment: return "tv.fill"
            }
        }
        
        // 获取每个分类对应的颜色
        var color: Color {
            switch self {
            case .all: return .primaryAccent
            case .apps: return .materialBlue
            case .games: return .fluentPurple
            case .productivity: return .materialGreen
            case .entertainment: return .materialRed
            }
        }
    }
    
    // 定义视图模式枚举
    enum ViewMode: String, CaseIterable {
        case grid = "网格"
        case list = "列表"
        
        // 获取每个视图模式对应的图标名称
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    // 定义排序选项枚举
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case name = "Name"
        case recent = "Recent"
        case rating = "Rating"
        case price = "Price"
        
        // 获取每个排序选项对应的系统图标名称
        var systemImage: String {
            switch self {
            case .relevance: return "star.fill"
            case .name: return "textformat.abc"
            case .recent: return "clock.fill"
            case .rating: return "heart.fill"
            case .price: return "dollarsign.circle.fill"
            }
        }
        
        // 获取每个排序选项的本地化名称
        var localizedName: String {
            switch self {
            case .relevance: return "相关性"
            case .name: return "名称"
            case .recent: return "最新"
            case .rating: return "评分"
            case .price: return "价格"
            }
        }
    }

    // 计算属性，获取可能的地区代码集合
    var possibleReigon: Set<String> {
        Set(vm.accounts.map(\.countryCode))
    }

    // 视图主体，定义视图的布局和结构
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [Color.surfacePrimary, Color.surfaceSecondary.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // 搜索头部区域
                        searchHeaderSection
                            .scaleEffect(animateHeader ? 1 : 0.95)
                            .opacity(animateHeader ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateHeader)
                        
                        // 分类选择器
                        categorySelector
                            .scaleEffect(animateHeader ? 1 : 0.95)
                            .opacity(animateHeader ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateHeader)
                        
                        // 搜索结果区域
                        searchResultsSection
                            .scaleEffect(animateResults ? 1 : 0.95)
                            .opacity(animateResults ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateResults)
                    }
                }
                .refreshable {
                    if !searchKey.isEmpty {
                        await performSearch()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            loadSearchHistory()
            startAnimations()
        }
        .sheet(isPresented: $showAdvancedFilters) {
            advancedFiltersSheet
        }
    }
    
    // MARK: - 搜索头部区域
    // 搜索头部区域视图
    var searchHeaderSection: some View {
        VStack(spacing: Spacing.lg) {
            // 标题和操作按钮
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("发现精彩")
                        .font(.displaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("探索无限")
                        .font(.bodyLarge)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: Spacing.sm) {
                    // 视图模式切换
                    Button {
                        withAnimation(.spring()) {
                            viewMode = viewMode == .grid ? .list : .grid
                        }
                    } label: {
                        Image(systemName: viewMode.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primaryAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.primaryAccent.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // 高级筛选
                    Button {
                        showAdvancedFilters.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondaryAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.secondaryAccent.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
            
            // 现代化搜索栏
            modernSearchBar
                .padding(.horizontal, Spacing.lg)
            
            // 搜索历史（如果显示）
            if showSearchHistory && !searchHistory.isEmpty {
                searchHistorySection
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .padding(.bottom, Spacing.lg)
    }
    
    // MARK: - 现代化搜索栏
    // 现代化搜索栏视图
    var modernSearchBar: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                // 搜索输入框
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(searchKeyFocused ? .primaryAccent : .secondary)
                    
                    TextField("搜索应用、游戏和更多内容...", text: $searchKey)
                        .font(.bodyLarge)
                        .focused($searchKeyFocused)
                        .onSubmit {
                            Task {
                                await performSearch()
                            }
                        }
                    
                    if !searchKey.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                searchKey = ""
                                searchResult = []
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !searchHistory.isEmpty {
                        Button {
                            withAnimation(.spring()) {
                                showSearchHistory.toggle()
                            }
                        } label: {
                            Image(systemName: showSearchHistory ? "clock.fill" : "clock")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primaryAccent)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .fill(Color.surfacePrimary)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .stroke(
                            searchKeyFocused ? Color.primaryAccent : Color.clear,
                            lineWidth: 2
                        )
                )
                
                // 搜索按钮
                Button {
                    Task {
                        await performSearch()
                    }
                } label: {
                    Group {
                        if searching {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryAccent, Color.primaryAccent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.primaryAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(searchKey.isEmpty || searching)
                .scaleEffect(searching ? 0.95 : 1.0)
                .animation(.spring(response: 0.3), value: searching)
            }
            
            // 搜索类型和地区选择
            HStack(spacing: Spacing.md) {
                // 搜索类型选择器
                Menu {
                    ForEach(EntityType.allCases, id: \.self) { type in
                        Button {
                            searchType = type
                        } label: {
                            HStack {
                                Image(systemName: type.systemImage)
                                Text(type.rawValue)
                                if searchType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: searchType.systemImage)
                            .font(.system(size: 14, weight: .medium))
                        Text(searchType.rawValue)
                            .font(.labelMedium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.primaryAccent)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.primaryAccent.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // 地区选择器
                buildRegionSelector()
            }
        }
    }
    
    // MARK: - 搜索历史区域
    // 搜索历史区域视图
    var searchHistorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("最近搜索", systemImage: "clock.arrow.circlepath")
                    .font(.labelLarge)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("清除全部") {
                    withAnimation(.easeInOut) {
                        clearSearchHistory()
                    }
                }
                .font(.labelMedium)
                .foregroundColor(.primaryAccent)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(searchHistory.prefix(8), id: \.self) { history in
                        Button {
                            searchKey = history
                            showSearchHistory = false
                            Task {
                                await performSearch()
                            }
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 12))
                                Text(history)
                                    .font(.labelMedium)
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(Color.surfaceSecondary)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.primaryAccent.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - 分类选择器
    // 分类选择器视图
    var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(SearchCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.spring()) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14, weight: .medium))
                            Text(category.rawValue)
                                .font(.labelLarge)
                        }
                        .foregroundColor(selectedCategory == category ? .white : category.color)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(
                                    selectedCategory == category
                                        ? category.color
                                        : category.color.opacity(0.1)
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedCategory == category
                                        ? Color.clear
                                        : category.color.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.bottom, Spacing.lg)
    }
    
    // MARK: - 搜索结果区域
    // 搜索结果区域视图
    var searchResultsSection: some View {
        VStack(spacing: Spacing.lg) {
            if !searchResult.isEmpty {
                // 结果统计和排序
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("找到 \(searchResult.count) 个结果")
                            .font(.titleMedium)
                            .foregroundColor(.primary)
                        
                        if !searchInput.isEmpty {
                            Text("关于 \"\(searchInput)\"")
                                .font(.bodySmall)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 排序选择器
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                                sortResults()
                            } label: {
                                HStack {
                                    Image(systemName: option.systemImage)
                                    Text(option.localizedName)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: sortOption.systemImage)
                                .font(.system(size: 14, weight: .medium))
                            Text(sortOption.localizedName)
                                .font(.labelMedium)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondaryAccent)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.secondaryAccent.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            
            // 搜索结果网格/列表
            if searching {
                searchingIndicator
            } else if searchResult.isEmpty {
                emptyStateView
            } else {
                searchResultsGrid
            }
        }
    }
    
    // MARK: - 搜索中指示器
    // 搜索中指示器视图
    var searchingIndicator: some View {
        VStack(spacing: Spacing.lg) {
            // 动画加载指示器
            ZStack {
                Circle()
                    .stroke(Color.primaryAccent.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primaryAccent, Color.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(searching ? 360 : 0))
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: searching
                    )
            }
            
            VStack(spacing: Spacing.xs) {
                Text("正在搜索...")
                    .font(.titleMedium)
                    .foregroundColor(.primary)
                
                Text("为您寻找最佳结果")
                    .font(.bodyMedium)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
    }
    
    // MARK: - 空状态视图
    // 空状态视图
    var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            // 空状态图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryAccent.opacity(0.1), Color.secondaryAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.primaryAccent.opacity(0.6))
            }
            
            VStack(spacing: Spacing.sm) {
                Text("开始您的探索之旅")
                    .font(.titleLarge)
                    .foregroundColor(.primary)
                
                Text("在上方搜索栏中输入关键词\n发现精彩的应用和游戏")
                    .font(.bodyMedium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // 推荐搜索
            if !searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("推荐搜索")
                        .font(.labelLarge)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: Spacing.sm) {
                        ForEach(searchHistory.prefix(3), id: \.self) { history in
                            Button {
                                searchKey = history
                                Task {
                                    await performSearch()
                                }
                            } label: {
                                Text(history)
                                    .font(.labelMedium)
                                    .foregroundColor(.primaryAccent)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(
                                        Capsule()
                                            .stroke(Color.primaryAccent.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, Spacing.md)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
        .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - 搜索结果网格
    // 搜索结果网格视图
    var searchResultsGrid: some View {
        LazyVStack(spacing: Spacing.md) {
            if viewMode == .grid {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: gridColumns),
                    spacing: Spacing.md
                ) {
                    ForEach(sortedResults().indices, id: \.self) { index in
                        let item = sortedResults()[index]
                        resultCardView(item: item, index: index)
                    }
                }
            } else {
                ForEach(sortedResults().indices, id: \.self) { index in
                    let item = sortedResults()[index]
                    resultListView(item: item, index: index)
                }
            }
            
            // 加载更多指示器
            if isLoadingMore {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("加载更多...")
                        .font(.labelMedium)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, Spacing.lg)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - 结果卡片视图
    // 结果卡片视图
    func resultCardView(item: iTunesResponse.iTunesArchive, index: Int) -> some View {
        NavigationLink(destination: ProductView(archive: item, region: searchRegion)) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // 应用图标
                AsyncImage(url: URL(string: item.artworkUrl512 ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [Color.surfaceSecondary, Color.surfaceTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "app.fill")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // 应用信息
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.name)
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.artistName ?? "未知开发者")
                        .font(.bodySmall)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // 价格和版本信息
                HStack(spacing: Spacing.xs) {
                    if let price = item.formattedPrice {
                        Text(price)
                            .font(.labelSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.primaryAccent)
                            )
                    }
                    
                    Text("v\(item.version)")
                        .font(.labelSmall)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.surfaceSecondary)
                        )
                    
                    Spacer()
                    
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondaryAccent)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.surfacePrimary)
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(.plain)
        .onAppear {
            // 当显示到倒数第3个项目时开始预加载
            if index >= searchResult.count - 3 && !isLoadingMore && searchResult.count >= pageSize {
                loadMoreResults()
            }
        }
    }
    
    // MARK: - 结果列表视图
    // 结果列表视图
    func resultListView(item: iTunesResponse.iTunesArchive, index: Int) -> some View {
        NavigationLink(destination: ProductView(archive: item, region: searchRegion)) {
            HStack(spacing: Spacing.md) {
                // 应用图标
                AsyncImage(url: URL(string: item.artworkUrl512 ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.surfaceSecondary)
                        .overlay {
                            Image(systemName: "app.fill")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                
                // 应用信息
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.name)
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.artistName ?? "未知开发者")
                        .font(.bodySmall)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: Spacing.xs) {
                        if let price = item.formattedPrice {
                            Text(price)
                                .font(.labelSmall)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryAccent)
                        }
                        
                        Text("v\(item.version)")
                            .font(.labelSmall)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.surfacePrimary)
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if index == searchResult.count - 1 && !isLoadingMore {
                loadMoreResults()
            }
        }
    }
    
    // MARK: - 地区选择器
    // 构建地区选择器视图
    func buildRegionSelector() -> some View {
        Menu {
            ForEach(regionKeys, id: \.self) { code in
                if let name = SearchView.countryCodeMap[code] {
                    Button {
                        searchRegion = code
                    } label: {
                        HStack {
                            Text("\(flag(country: code)) \(name)")
                            if searchRegion == code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(flag(country: searchRegion))
                    .font(.system(size: 14))
                Text(SearchView.countryCodeMap[searchRegion] ?? searchRegion)
                    .font(.labelMedium)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.secondaryAccent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.secondaryAccent.opacity(0.1))
            )
        }
    }
    
    // MARK: - 高级筛选面板
    // 高级筛选面板视图
    var advancedFiltersSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // 排序选项
                    ModernCard(style: .filled, padding: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Label("排序方式", systemImage: "arrow.up.arrow.down")
                                .font(.titleMedium)
                                .foregroundColor(.primaryAccent)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.sm) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button {
                                        sortOption = option
                                        sortResults()
                                    } label: {
                                        HStack(spacing: Spacing.sm) {
                                            Image(systemName: option.systemImage)
                                                .font(.system(size: 16, weight: .medium))
                                            Text(option.localizedName)
                                                .font(.labelLarge)
                                            Spacer()
                                            if sortOption == option {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.primaryAccent)
                                            }
                                        }
                                        .foregroundColor(sortOption == option ? .primaryAccent : .primary)
                                        .padding(Spacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                                .fill(
                                                    sortOption == option
                                                        ? Color.primaryAccent.opacity(0.1)
                                                        : Color.clear
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // 视图选项
                    ModernCard(style: .filled, padding: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Label("显示方式", systemImage: "rectangle.grid.2x2")
                                .font(.titleMedium)
                                .foregroundColor(.secondaryAccent)
                            
                            HStack(spacing: Spacing.md) {
                                ForEach(ViewMode.allCases, id: \.self) { mode in
                                    Button {
                                        viewMode = mode
                                    } label: {
                                        HStack(spacing: Spacing.sm) {
                                            Image(systemName: mode.icon)
                                                .font(.system(size: 16, weight: .medium))
                                            Text(mode.rawValue)
                                                .font(.labelLarge)
                                            Spacer()
                                            if viewMode == mode {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.secondaryAccent)
                                            }
                                        }
                                        .foregroundColor(viewMode == mode ? .secondaryAccent : .primary)
                                        .padding(Spacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                                .fill(
                                                    viewMode == mode
                                                        ? Color.secondaryAccent.opacity(0.1)
                                                        : Color.clear
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            if viewMode == .grid {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("网格列数: \(gridColumns)")
                                        .font(.labelMedium)
                                        .foregroundColor(.secondary)
                                    
                                    Slider(value: Binding(
                                        get: { Double(gridColumns) },
                                        set: { gridColumns = Int($0) }
                                    ), in: 1...3, step: 1)
                                    .tint(.secondaryAccent)
                                }
                            }
                        }
                    }
                    
                    // 搜索历史管理
                    if !searchHistory.isEmpty {
                        ModernCard(style: .filled, padding: Spacing.lg) {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack {
                                    Label("搜索历史", systemImage: "clock.fill")
                                        .font(.titleMedium)
                                        .foregroundColor(.materialAmber)
                                    
                                    Spacer()
                                    
                                    Button("清除全部") {
                                        clearSearchHistory()
                                    }
                                    .font(.labelMedium)
                                    .foregroundColor(.materialRed)
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.xs) {
                                    ForEach(searchHistory.prefix(10), id: \.self) { history in
                                        HStack {
                                            Button {
                                                searchKey = history
                                                showAdvancedFilters = false
                                                Task {
                                                    await performSearch()
                                                }
                                            } label: {
                                                HStack(spacing: Spacing.xs) {
                                                    Image(systemName: "clock")
                                                        .font(.system(size: 12))
                                                    Text(history)
                                                        .font(.labelMedium)
                                                    Spacer()
                                                }
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Button {
                                                removeFromHistory(history)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.vertical, Spacing.xs)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("搜索筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showAdvancedFilters = false
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    // 启动视图动画
    func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateHeader = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateResults = true
        }
    }
    
    // 根据国家代码获取对应的国旗 emoji
    func flag(country: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in country.unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return String(s)
    }
    
    // 执行搜索操作
    @MainActor
    func performSearch() async {
        guard !searchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        withAnimation(.easeInOut) {
            searching = true
            searchResult = []
            currentPage = 1
        }
        
        searchInput = searchKey
        addToSearchHistory(searchKey)
        showSearchHistory = false
        
        do {
            // 创建 iTunes 搜索请求
            let httpClient = HTTPClient(urlSession: URLSession.shared)
            let itunesClient = iTunesClient(httpClient: httpClient)
            let response = try await itunesClient.searchAsync(
                type: searchType,
                term: searchKey,
                limit: pageSize,
                offset: nil,
                region: searchRegion
            )
            
            await MainActor.run {
                withAnimation(.spring()) {
                    searchResult = response
                    searching = false
                }
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeInOut) {
                    searching = false
                }
            }
        }
    }
    
    // 加载搜索历史记录
    func loadSearchHistory() {
        if let data = try? JSONDecoder().decode([String].self, from: searchHistoryData) {
            searchHistory = data
        }
    }
    
    // 保存搜索历史记录
    func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            searchHistoryData = data
        }
    }
    
    // 将搜索词添加到搜索历史记录中
    func addToSearchHistory(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // 移除重复项
        searchHistory.removeAll { $0 == trimmedQuery }
        // 添加到开头
        searchHistory.insert(trimmedQuery, at: 0)
        // 限制历史记录数量
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        saveSearchHistory()
    }
    
    // 从搜索历史记录中移除指定的搜索词
    func removeFromHistory(_ query: String) {
        searchHistory.removeAll { $0 == query }
        saveSearchHistory()
    }
    
    // 清除所有搜索历史记录
    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
        showSearchHistory = false
    }
    
    // 根据排序选项对搜索结果进行排序
    func sortedResults() -> [iTunesResponse.iTunesArchive] {
        switch sortOption {
        case .relevance:
            return searchResult
        case .name:
            return searchResult.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
        case .recent:
            return searchResult.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
        case .rating:
            return searchResult.sorted(by: { ($0.price ?? 0) < ($1.price ?? 0) })
        case .price:
            return searchResult.sorted(by: { ($0.price ?? 0) < ($1.price ?? 0) })
        }
    }
    
    // 触发搜索结果排序
    func sortResults() {
        // 触发视图更新
        let _ = sortedResults()
    }
    
    // 加载更多搜索结果
    func loadMoreResults() {
        guard !isLoadingMore && !searching && !searchKey.isEmpty else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        Task {
            do {
                let httpClient = HTTPClient(urlSession: URLSession.shared)
                let iTunesClient = iTunesClient(httpClient: httpClient)
                let offset = (currentPage - 1) * pageSize
                let response = try await iTunesClient.searchAsync(
                    type: searchType,
                    term: searchKey,
                    limit: pageSize,
                    offset: offset,
                    region: searchRegion
                )
                
                await MainActor.run {
                    // 只有当返回的结果不为空时才添加
                    if !response.isEmpty {
                        searchResult.append(contentsOf: response)
                    }
                    isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    isLoadingMore = false
                    currentPage -= 1
                }
            }
        }
    }
}
