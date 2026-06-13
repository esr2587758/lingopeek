import Foundation
import LingobarCore

let apiKey = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] ?? ""
let model = ProcessInfo.processInfo.environment["DEEPSEEK_MODEL"] ?? "deepseek-v4-flash"
let baseURL = URL(string: ProcessInfo.processInfo.environment["DEEPSEEK_BASE_URL"] ?? "https://api.deepseek.com")!

let client = DeepSeekClient(baseURL: baseURL, apiKey: apiKey, model: model)
let system = "You are a concise bilingual English learning assistant. Reply in Chinese with one natural English sentence."
let user = "把“选中即解析，输入即生成”改写成自然英文产品标语。"

do {
    let text = try await client.complete(system: system, user: user)
    print("DeepSeek model: \(model)")
    print("Completion:")
    print(text)
} catch {
    fputs("DeepSeek probe failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
