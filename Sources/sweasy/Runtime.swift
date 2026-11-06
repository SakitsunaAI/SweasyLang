import Foundation

/// The Sweasy Runtime Library
/// This code is embedded directly into transpiled Swift programs,
/// giving Sweasy scripts access to high-level, human-friendly operations.
public enum SweasyRuntime {
    public static let code: String = #"""
// --- BEGIN SWEASY RUNTIME ---
import Foundation

// MARK: - Display & Printing
func _sweasy_print(_ items: Any...) {
    let output = items.map { item -> String in
        if let opt = item as? (any OptionalProtocol) {
            return opt.isNil ? "nil" : "\(opt.unwrappedValue)"
        }
        return "\(item)"
    }.joined(separator: " ")
    print(output)
}

protocol OptionalProtocol {
    var isNil: Bool { get }
    var unwrappedValue: Any { get }
}

extension Optional: OptionalProtocol {
    var isNil: Bool { self == nil }
    var unwrappedValue: Any {
        switch self {
        case .some(let val): return val
        case .none: return "nil"
        }
    }
}

// MARK: - User Input
func _sweasy_ask(_ prompt: String = "") -> String {
    if !prompt.isEmpty {
        print(prompt, terminator: "")
        fflush(stdout)
    }
    return readLine() ?? ""
}

func _sweasy_ask_number(_ prompt: String = "") -> Double {
    let input = _sweasy_ask(prompt).trimmingCharacters(in: .whitespacesAndNewlines)
    return Double(input) ?? 0.0
}

func _sweasy_ask_int(_ prompt: String = "") -> Int {
    let input = _sweasy_ask(prompt).trimmingCharacters(in: .whitespacesAndNewlines)
    return Int(input) ?? 0
}

// MARK: - Timing & Date
func _sweasy_wait(seconds: Double) {
    let microSeconds = useconds_t(seconds * 1_000_000)
    usleep(microSeconds)
}

func _sweasy_date() -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: Date())
}

func _sweasy_time() -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter.string(from: Date())
}

// MARK: - Randomization
func _sweasy_random_int(from: Int, to: Int) -> Int {
    guard from <= to else { return Int.random(in: to...from) }
    return Int.random(in: from...to)
}

func _sweasy_random_number(from: Double, to: Double) -> Double {
    guard from <= to else { return Double.random(in: to...from) }
    return Double.random(in: from...to)
}

// MARK: - Collections Helpers
func _sweasy_add<T>(_ item: T, to list: inout [T]) {
    list.append(item)
}

func _sweasy_remove<T: Equatable>(_ item: T, from list: inout [T]) {
    if let idx = list.firstIndex(of: item) {
        list.remove(at: idx)
    }
}

func _sweasy_remove_at<T>(_ index: Int, from list: inout [T]) {
    guard index >= 0 && index < list.count else { return }
    list.remove(at: index)
}

func _sweasy_first<T>(_ list: [T]) -> T? {
    list.first
}

func _sweasy_last<T>(_ list: [T]) -> T? {
    list.last
}

func _sweasy_length(_ list: [Any]) -> Int {
    list.count
}

func _sweasy_length(_ string: String) -> Int {
    string.count
}

// MARK: - String Helpers
func _sweasy_split(_ text: String, by separator: String) -> [String] {
    return text.components(separatedBy: separator)
}

func _sweasy_join(_ items: [Any], with separator: String) -> String {
    return items.map { "\($0)" }.joined(separator: separator)
}

func _sweasy_uppercase(_ text: String) -> String {
    return text.uppercased()
}

func _sweasy_lowercase(_ text: String) -> String {
    return text.lowercased()
}

func _sweasy_contains(_ text: String, sub: String) -> Bool {
    return text.contains(sub)
}

func _sweasy_contains<T: Equatable>(_ list: [T], item: T) -> Bool {
    return list.contains(item)
}

// MARK: - File I/O
func _sweasy_write_file(_ text: String, to path: String) -> Bool {
    do {
        try text.write(toFile: path, atomically: true, encoding: .utf8)
        return true
    } catch {
        print("Sweasy Error: Could not write to file '\(path)': \(error.localizedDescription)")
        return false
    }
}

func _sweasy_append_file(_ text: String, to path: String) -> Bool {
    guard let data = text.data(using: .utf8) else { return false }
    if let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(data)
        handle.closeFile()
        return true
    } else {
        return _sweasy_write_file(text, to: path)
    }
}

func _sweasy_read_file(_ path: String) -> String {
    do {
        return try String(contentsOfFile: path, encoding: .utf8)
    } catch {
        print("Sweasy Error: Could not read file '\(path)': \(error.localizedDescription)")
        return ""
    }
}

func _sweasy_file_exists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

func _sweasy_delete_file(_ path: String) -> Bool {
    do {
        try FileManager.default.removeItem(atPath: path)
        return true
    } catch {
        return false
    }
}

// MARK: - Web & HTTP
func _sweasy_fetch_url(_ urlString: String) -> String {
    guard let url = URL(string: urlString) else {
        print("Sweasy Error: Invalid URL: \(urlString)")
        return ""
    }
    do {
        return try String(contentsOf: url, encoding: .utf8)
    } catch {
        print("Sweasy Error: Failed fetching URL: \(error.localizedDescription)")
        return ""
    }
}

// MARK: - Shell Execution
func _sweasy_shell(_ command: String) -> String {
    let process = Process()
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", command]
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    } catch {
        return ""
    }
}
// --- END SWEASY RUNTIME ---

"""#
}

