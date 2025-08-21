import Combine
import Foundation

// 持久化提供者协议，定义数据存储和读取的基本接口
protocol PersistProvider {
    // 通过键名读取数据
    func data(forKey: String) -> Data?
    // 通过键名存储数据
    func set(_ data: Data?, forKey: String)
}

// JSON编码器实例
private let valueEncoder = JSONEncoder()
// JSON解码器实例
private let valueDecoder = JSONDecoder()
// 配置文件存储目录
private let configDir = APP.documentsDirectory
    .appendingPathComponent("Config")

// 文件存储实现类，遵循PersistProvider协议
class FileStorage: PersistProvider {
    // 根据键名生成文件存储路径
    func pathForKey(_ key: String) -> URL {
        // 创建配置目录（如果不存在）
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        var url = configDir.appendingPathComponent(key)
        var resourceValues = URLResourceValues()
        // 设置文件不备份到iCloud
        resourceValues.isExcludedFromBackup = true
        try? url.setResourceValues(resourceValues)
        return url
    }

    // 通过键名读取数据
    func data(forKey key: String) -> Data? {
        try? Data(contentsOf: pathForKey(key))
    }

    // 通过键名存储数据
    func set(_ data: Data?, forKey key: String) {
        try? data?.write(to: pathForKey(key))
    }
}

// 持久化属性包装器，用于自动保存和加载可编码值
@propertyWrapper
struct Persist<Value: Codable> {
    // 当前值的主题发布者
    private let subject: CurrentValueSubject<Value, Never>
    // 取消令牌集合，用于管理订阅
    private let cancellables: Set<AnyCancellable>

    // 公开的发布者，允许外部监听值的变化
    public var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }

    // 初始化持久化属性包装器
    public init(key: String, defaultValue: Value, engine: PersistProvider) {
        // 尝试从存储引擎加载数据
        if let data = engine.data(forKey: key),
           let object = try? valueDecoder.decode(Value.self, from: data)
        {
            subject = CurrentValueSubject<Value, Never>(object)
        } else {
            // 如果加载失败，使用默认值
            subject = CurrentValueSubject<Value, Never>(defaultValue)
        }

        // 设置值变化的监听和自动保存
        var cancellables: Set<AnyCancellable> = .init()
        subject
            .receive(on: DispatchQueue.global()) // 在后台队列处理
            .map { try? valueEncoder.encode($0) } // 编码为Data
            .removeDuplicates() // 移除重复值
            .sink { engine.set($0, forKey: key) } // 保存到存储引擎
            .store(in: &cancellables)
        self.cancellables = cancellables
    }

    // 包装值，支持读取和写入
    public var wrappedValue: Value {
        get { subject.value }
        set { subject.send(newValue) }
    }
}

// 持久化属性包装器，结合了@Published和@Persist的功能
@propertyWrapper
struct PublishedPersist<Value: Codable> {
    // 内部使用@Persist存储值
    @Persist private var value: Value

    // 公开的发布者，允许外部监听值的变化
    public var projectedValue: AnyPublisher<Value, Never> { $value }

    // 禁用wrappedValue的直接访问，防止未定义行为
    @available(*, unavailable, message: "accessing wrappedValue will result undefined behavior")
    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    // 静态下标，用于与ObservableObject集成
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped _: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedPersist<Value>>
    ) -> Value {
        get { object[keyPath: storageKeyPath].value }
        set {
            // 发送对象即将改变的通知
            (object.objectWillChange as? ObservableObjectPublisher)?.send()
            object[keyPath: storageKeyPath].value = newValue
        }
    }

    // 初始化可发布持久化属性包装器
    public init(key: String, defaultValue: Value, engine: PersistProvider) {
        _value = .init(key: key, defaultValue: defaultValue, engine: engine)
    }
}

// Persist结构体的扩展，提供使用默认文件存储引擎的初始化方法
extension Persist {
    init(key: String, defaultValue: Value) {
        self.init(key: key, defaultValue: defaultValue, engine: FileStorage())
    }
}

// PublishedPersist结构体的扩展，提供使用默认文件存储引擎的初始化方法
extension PublishedPersist {
    init(key: String, defaultValue: Value) {
        self.init(key: key, defaultValue: defaultValue, engine: FileStorage())
    }
}
