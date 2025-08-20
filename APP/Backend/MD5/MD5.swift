// 导入必要的框架
import CommonCrypto  // 通用加密库
import CryptoKit     // 加密工具包
import Foundation    // 基础框架

/// 计算文件的MD5哈希值
/// - Parameter url: 文件的URL路径
/// - Returns: MD5哈希字符串，如果计算失败则返回nil
func md5File(url: URL) -> String? {
    do {
        // 创建MD5哈希器
        var hasher = Insecure.MD5()
        // 设置缓冲区大小为32MB
        let bufferSize = 1024 * 1024 * 32 // 32MB

        // 打开文件进行读取
        let fileHandler = try FileHandle(forReadingFrom: url)
        // 移动到文件末尾以获取文件大小
        fileHandler.seekToEndOfFile()
        // 获取文件大小
        let size = fileHandler.offsetInFile
        // 移动回文件开头
        try fileHandler.seek(toOffset: 0)

        // 循环读取文件内容直到结束
        while fileHandler.offsetInFile < size {
            // 使用自动释放池管理内存
            autoreleasepool {
                // 读取数据到缓冲区
                let data = fileHandler.readData(ofLength: bufferSize)
                // 更新MD5哈希
                hasher.update(data: data)
            }
        }

        // 完成哈希计算
        let digest = hasher.finalize()
        // 将哈希结果转换为十六进制字符串
        return digest.map { String(format: "%02hhx", $0) }.joined()
    } catch {
        // 打印错误信息
        print("[-] 读取文件错误: \(error)")
        // 返回nil表示计算失败
        return nil
    }
}
