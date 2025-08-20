// 导入必要的框架
import ApplePackage
import Combine
import Foundation

/// AppStore类：管理应用商店相关功能，遵循ObservableObject协议以便于UI响应式更新
class AppStore: ObservableObject {
    /// 账户结构体：存储账户信息，支持编码、解码、唯一标识和哈希
    struct Account: Codable, Identifiable, Hashable {
        /// 使用邮箱作为唯一标识符
        var id: String { email }

        var email: String          // 账户邮箱
        var password: String       // 账户密码
        var countryCode: String    // 国家代码
        var storeResponse: StoreResponse.Account  // 商店响应的账户信息
    }

    /// 存储订阅者集合，用于管理Combine框架的订阅关系
    var cancellables: Set<AnyCancellable> = .init()

    /// 设备种子地址：使用PublishedPersist属性包装器持久化存储
    @PublishedPersist(key: "DeviceSeedAddress", defaultValue: "")
    var deviceSeedAddress: String

    /// 创建随机设备种子
    /// - Returns: 生成的12位大写十六进制字符串
    static func createSeed() -> String {
        // 生成格式如00:00:00:00:00:00的MAC地址，然后转换为大写十六进制字符串
        "00:00:00:00:00:00"
            .components(separatedBy: ":")
            .map { _ in
                let randomHex = String(Int.random(in: 0 ... 255), radix: 16)
                return randomHex.count == 1 ? "0\(randomHex)" : randomHex
            }
            .joined(separator: ":")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .uppercased()
    }

    /// 账户列表：使用PublishedPersist属性包装器持久化存储
    @PublishedPersist(key: "Accounts", defaultValue: [])
    var accounts: [Account]

    /// 演示模式：使用PublishedPersist属性包装器持久化存储
    @PublishedPersist(key: "DemoMode", defaultValue: false)
    var demoMode: Bool

    /// 单例实例：全局访问点
    static let this = AppStore()
    /// 私有初始化方法：设置订阅
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

    /// 设置GUID：如果deviceSeedAddress为空，则创建新种子
    func setupGUID() {
        // 如果设备种子地址为空，则创建一个新的
        if deviceSeedAddress.isEmpty { deviceSeedAddress = Self.createSeed() }
        // 断言确保deviceSeedAddress不为空
        assert(!deviceSeedAddress.isEmpty)
        // 触发属性更新通知
        deviceSeedAddress = deviceSeedAddress
    }

    /// 保存账户信息
    /// - Parameters:
    ///   - email: 账户邮箱
    ///   - password: 账户密码
    ///   - account: 商店响应的账户信息
    /// - Returns: 保存的账户对象
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

    /// 删除AppleID
    /// - Parameter id: 要删除的AppleID
    func delete(id: Account.ID) {
        // 过滤掉指定ID的账户
        accounts = accounts.filter { $0.id != id }
    }

    /// 更新账户信息
    /// - Parameter id: 要更新的账户ID
    /// - Returns: 更新后的账户对象，若未找到则返回nil
    /// - Throws: 认证过程中可能抛出的错误
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
