// 导入必要的框架
import ApplePackage  // Apple包处理库
import Combine       // 响应式编程框架
import Foundation    // 基础框架

/// AppStore类，管理应用商店相关功能
/// 遵循ObservableObject协议，支持UI响应式更新
public class AppStore: ObservableObject {
    /// 账户结构体，存储App Store账户信息
    /// 遵循Codable、Identifiable和Hashable协议
    public struct Account: Codable, Identifiable, Hashable {
        /// 唯一标识符，使用邮箱确保唯一性
        public var id: String { email }
        /// 账户邮箱，用于登录和识别
        public var email: String
        /// 账户密码，用于登录验证
        public var password: String
        /// 国家代码（如CN、US）
        public var countryCode: String
        /// 商店响应的账户信息
        public var storeResponse: StoreResponse.Account
    }

    /// Combine订阅者集合，管理订阅关系避免内存泄漏
    var cancellables: Set<AnyCancellable> = .init()

    /// 设备种子地址，持久化存储
    /// 用于生成唯一的设备标识符
    @PublishedPersist(key: "DeviceSeedAddress", defaultValue: "")
    var deviceSeedAddress: String

    /// 创建随机设备标识符
    /// 生成12位大写十六进制字符串
    static func createSeed() -> String {
        // 生成格式如00:00:00:00:00:00的MAC地址，然后转换为大写十六进制字符串
        // 1. 从一个样例MAC地址字符串开始
        "00:00:00:00:00:00"
            // 2. 按冒号分割字符串，得到6个部分
            .components(separatedBy: ":")
            // 3. 将每个部分替换为随机生成的0-255之间的十六进制值
            .map { _ in
                // 生成0-255之间的随机数，并转换为十六进制字符串
                let randomHex = String(Int.random(in: 0 ... 255), radix: 16)
                // 确保生成的十六进制值是两位数，不足前面补0
                return randomHex.count == 1 ? "0\(randomHex)" : randomHex
            }
            // 4. 用冒号连接所有部分，形成MAC地址格式
            .joined(separator: ":")
            // 5. 去除首尾的空白字符
            .trimmingCharacters(in: .whitespacesAndNewlines)
            // 6. 移除所有冒号，得到纯十六进制字符串
            .replacingOccurrences(of: ":", with: "")
            // 7. 转换为大写
            .uppercased()
    }

    /// 账户列表，持久化存储
    @PublishedPersist(key: "Accounts", defaultValue: [])
    var accounts: [Account]

    /// 启用时提供演示功能，不进行实际网络请求
    @PublishedPersist(key: "DemoMode", defaultValue: false)
    var demoMode: Bool

    /// 单例实例，全局访问点
    static let this = AppStore()
    /// 私有初始化方法
    /// 防止外部创建新实例，设置设备种子地址订阅
    private init() {
        // 监听deviceSeedAddress变化，并更新ApplePackage的overrideGUID
        $deviceSeedAddress
            .removeDuplicates()
            .sink { input in
                print("[*] 更新guid \(input) 作为种子")
                ApplePackage.overrideGUID = input
            }
            .store(in: &cancellables)
    }

    /// 设置GUID，如为空则创建新种子
    func setupGUID() {
        // 如果设备种子地址为空，则创建一个新的
        if deviceSeedAddress.isEmpty { deviceSeedAddress = Self.createSeed() }
        // 断言确保deviceSeedAddress不为空
        assert(!deviceSeedAddress.isEmpty)
        // 触发属性更新通知
        deviceSeedAddress = deviceSeedAddress
    }

    /// 保存账户信息
    @discardableResult
    func save(email: String, password: String, account: StoreResponse.Account) -> Account {
        // 创建账户对象
        let account = Account(
            email: email,
            password: password,
            countryCode: account.countryCode,
            storeResponse: account
        )
        // 过滤掉相同邮箱的账户（不区分大小写）
        accounts = accounts
            .filter { $0.email.lowercased() != email.lowercased() }
            // 添加新账户
            + [account]
        return account
    }

    /// 删除AppleID账户
    func delete(id: Account.ID) {
        // 过滤掉指定ID的账户
        accounts = accounts.filter { $0.id != id }
    }

    /// 更新账户信息
    @discardableResult
    func rotate(id: Account.ID) throws -> Account? {
        // 查找指定ID的账户
        guard let account = accounts.first(where: { $0.id == id }) else { return nil }
        // 创建认证器
        let auth = ApplePackage.Authenticator(email: account.email)
        // 尝试重新认证
        let newAccount = try auth.authenticate(password: account.password, code: nil)
        // 检查是否在主线程
        if Thread.isMainThread {
            // 如果在主线程，直接保存
            return save(email: account.email, password: account.password, account: newAccount)
        } else {
            // 如果不在主线程，使用异步方式在主线程执行保存
            var result: Account?
            DispatchQueue.main.asyncAndWait {
                result = self.save(email: account.email, password: account.password, account: newAccount)
            }
            return result
        }
    }
}
