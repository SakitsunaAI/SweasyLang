import Foundation

/// Interactive Read-Eval-Print-Loop (REPL) for the Sweasy Language.
public final class REPL {
    private let compiler = Compiler()
    private var sessionLines: [String] = []

    public init() {}

    public func start() {
        printBanner()

        var multiLineBuffer: [String] = []
        var inBlock = false

        while true {
            let prompt = inBlock ? "... " : "sweasy> "
            print(prompt, terminator: "")
            fflush(stdout)

            guard let rawLine = readLine() else {
                print("\nGoodbye!")
                break
            }

            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                continue
            }

            // Commands
            if !inBlock {
                let lower = line.lowercased()
                if lower == "exit" || lower == "quit" || lower == ":q" {
                    print("Goodbye!")
                    break
                }
                if lower == ":reset" || lower == "reset" {
                    sessionLines.removeAll()
                    print("✓ Session reset.")
                    continue
                }
                if lower == ":swift" {
                    print("// Current Swift session code:")
                    let currentCode = sessionLines.joined(separator: "\n")
                    if let transpiled = try? compiler.transpile(source: currentCode) {
                        print(transpiled)
                    }
                    continue
                }
                if lower == "help" || lower == ":help" {
                    printHelp()
                    continue
                }
            }

            // Check if starting a block
            let lower = line.lowercased()
            if !inBlock && (lower.hasPrefix("if ") ||
                            lower.hasPrefix("repeat") ||
                            lower.hasPrefix("while ") ||
                            lower.hasPrefix("for each ") ||
                            lower.hasPrefix("function ") ||
                            lower.hasPrefix("to ") ||
                            lower.hasPrefix("swift:") ||
                            lower == "swift") && line.hasSuffix(":") {
                inBlock = true
                multiLineBuffer.append(line)
                continue
            }

            if inBlock {
                multiLineBuffer.append(line)
                let cleanEnd = line.trimmingCharacters(in: CharacterSet(charactersIn: " .:")).lowercased()
                if cleanEnd == "end" ||
                   cleanEnd == "end if" ||
                   cleanEnd == "end repeat" ||
                   cleanEnd == "end while" ||
                   cleanEnd == "end for" ||
                   cleanEnd == "end function" ||
                   cleanEnd == "end to" ||
                   cleanEnd == "end swift" {
                    inBlock = false
                    let blockCode = multiLineBuffer.joined(separator: "\n")
                    multiLineBuffer.removeAll()
                    evaluate(code: blockCode, addToSession: true)
                }
                continue
            }

            // Single line evaluation
            evaluate(code: line, addToSession: true)
        }
    }

    private func evaluate(code: String, addToSession: Bool) {
        var trialLines = sessionLines
        var effectiveCode = code

        // If the line is an expression without a verb, wrap it in a Say statement for convenience
        let lower = code.lowercased()
        let isStatementVerb = lower.hasPrefix("say ") ||
                              lower.hasPrefix("show ") ||
                              lower.hasPrefix("print ") ||
                              lower.hasPrefix("display ") ||
                              lower.hasPrefix("set ") ||
                              lower.hasPrefix("let ") ||
                              lower.hasPrefix("remember ") ||
                              lower.hasPrefix("define ") ||
                              lower.hasPrefix("change ") ||
                              lower.hasPrefix("increase ") ||
                              lower.hasPrefix("decrease ") ||
                              lower.hasPrefix("multiply ") ||
                              lower.hasPrefix("divide ") ||
                              lower.hasPrefix("ask ") ||
                              lower.hasPrefix("add ") ||
                              lower.hasPrefix("remove ") ||
                              lower.hasPrefix("clear ") ||
                              lower.hasPrefix("sort ") ||
                              lower.hasPrefix("reverse ") ||
                              lower.hasPrefix("wait ") ||
                              lower.hasPrefix("sleep ") ||
                              lower.hasPrefix("get ") ||
                              lower.hasPrefix("write ") ||
                              lower.hasPrefix("append ") ||
                              lower.hasPrefix("delete ") ||
                              lower.hasPrefix("read ") ||
                              lower.hasPrefix("fetch ") ||
                              lower.hasPrefix("run ") ||
                              lower.hasPrefix("call ") ||
                              lower.hasPrefix("swift:") ||
                              lower.contains(" = ") ||
                              lower.hasPrefix("if ") ||
                              lower.hasPrefix("repeat") ||
                              lower.hasPrefix("while ") ||
                              lower.hasPrefix("for each ") ||
                              lower.hasPrefix("function ") ||
                              lower.hasPrefix("to ")

        if !isStatementVerb {
            effectiveCode = "Say \(code)"
        }

        trialLines.append(effectiveCode)
        let fullSource = trialLines.joined(separator: "\n")

        do {
            try compiler.run(source: fullSource)
            if addToSession {
                sessionLines.append(effectiveCode)
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func printBanner() {
        print("""
\u{001B}[1;36m
   ____                               
  / ___|_      _____  __ _ ___ _   _  
  \\___ \\ \\ /\\ / / _ \\/ _` / __| | | | 
   ___) \\ V  V /  __/ (_| \\__ \\ |_| | 
  |____/ \\_/\\_/ \\___|\\__,_|___/\\__, | 
                               |___/  
\u{001B}[0m
\u{001B}[1mSweasy (Swift + Easy)\u{001B}[0m — The World's Easiest Programming Language
Powered by Apple Swift 6

• Write in plain English sentences.
• Type \u{001B}[33mhelp\u{001B}[0m for quick examples.
• Type \u{001B}[33m:swift\u{001B}[0m to inspect generated Swift code.
• Type \u{001B}[33m:reset\u{001B}[0m to clear session memory.
• Type \u{001B}[33mexit\u{001B}[0m to quit.
""")
    }

    private func printHelp() {
        print("""
Sweasy Quick Guide & Examples:
  \u{001B}[32mSay "Hello, World!"\u{001B}[0m                   Display text
  \u{001B}[32mSet name to "Alice"\u{001B}[0m                   Define variable
  \u{001B}[32mSay "Welcome {name}!"\u{001B}[0m                 String interpolation
  \u{001B}[32mIncrease count by 1\u{001B}[0m                   Math mutation
  \u{001B}[32mAsk user for age as integer with "Age: "\u{001B}[0m User input
  \u{001B}[32mGet random number between 1 and 100 into r\u{001B}[0m Random numbers
  \u{001B}[32mRepeat 3 times:\u{001B}[0m                       Loops
  \u{001B}[32m    Say "Sweasy is awesome!"\u{001B}[0m
  \u{001B}[32mEnd\u{001B}[0m
""")
    }
}
