import Foundation

@main
struct SweasyCLI {
    static let version = "1.0.0"

    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.isEmpty {
            // Start REPL by default when run without arguments
            let repl = REPL()
            repl.start()
            return
        }

        let command = args[0].lowercased()

        switch command {
        case "repl":
            let repl = REPL()
            repl.start()

        case "run":
            handleRun(arguments: Array(args.dropFirst()))

        case "build":
            handleBuild(arguments: Array(args.dropFirst()))

        case "transpile":
            handleTranspile(arguments: Array(args.dropFirst()))

        case "new", "init":
            handleNew(arguments: Array(args.dropFirst()))

        case "examples":
            handleExamples(arguments: Array(args.dropFirst()))

        case "--version", "-v", "version":
            print("Sweasy version \(version) (targeting Apple Swift 6.x)")

        case "--help", "-h", "help":
            printHelp()

        default:
            // If the user provided a filename directly: `sweasy app.sweasy`
            if command.hasSuffix(".sweasy") || FileManager.default.fileExists(atPath: args[0]) {
                handleRun(arguments: args)
            } else {
                print("Unknown command: '\(args[0])'")
                print("Type 'sweasy help' for a list of available commands.")
                exit(1)
            }
        }
    }

    // MARK: - Handlers

    static func handleRun(arguments: [String]) {
        guard let filePath = arguments.first else {
            print("Usage: sweasy run <file.sweasy> [arguments...]")
            exit(1)
        }

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("Error: File '\(filePath)' not found.")
            exit(1)
        }

        do {
            let source = try String(contentsOfFile: filePath, encoding: .utf8)
            let compiler = Compiler()
            let programArgs = Array(arguments.dropFirst())
            let exitCode = try compiler.run(source: source, arguments: programArgs)
            if exitCode != 0 {
                exit(exitCode)
            }
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    static func handleBuild(arguments: [String]) {
        guard let filePath = arguments.first else {
            print("Usage: sweasy build <file.sweasy> [-o <output-binary>]")
            exit(1)
        }

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("Error: File '\(filePath)' not found.")
            exit(1)
        }

        var outputPath = URL(fileURLWithPath: filePath).deletingPathExtension().path
        if arguments.count >= 3 && arguments[1] == "-o" {
            outputPath = arguments[2]
        }

        print("Compiling \(filePath) with Swift compiler (swiftc -O)...")

        do {
            let source = try String(contentsOfFile: filePath, encoding: .utf8)
            let compiler = Compiler()
            let startTime = CFAbsoluteTimeGetCurrent()
            try compiler.build(source: source, outputPath: outputPath)
            let duration = String(format: "%.2f", CFAbsoluteTimeGetCurrent() - startTime)
            print("✓ Successfully built native binary: \(outputPath) (\(duration)s)")
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    static func handleTranspile(arguments: [String]) {
        guard let filePath = arguments.first else {
            print("Usage: sweasy transpile <file.sweasy> [-o <output.swift>]")
            exit(1)
        }

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("Error: File '\(filePath)' not found.")
            exit(1)
        }

        do {
            let source = try String(contentsOfFile: filePath, encoding: .utf8)
            let compiler = Compiler()
            let swiftCode = try compiler.transpile(source: source)

            if arguments.count >= 3 && arguments[1] == "-o" {
                let outPath = arguments[2]
                try swiftCode.write(toFile: outPath, atomically: true, encoding: .utf8)
                print("✓ Transpiled Swift code written to: \(outPath)")
            } else {
                print(swiftCode)
            }
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    static func handleNew(arguments: [String]) {
        let projectName = arguments.first ?? "MySweasyApp"
        let projectURL = URL(fileURLWithPath: projectName)

        do {
            try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)
            let mainFile = projectURL.appendingPathComponent("main.sweasy")
            let sampleCode = #"""
# Welcome to your new Sweasy application!

Say "Hello from Sweasy!"
Say "This language is written in simple English sentences."

Set name to "Friend"
Say "Welcome, {name}!"

Get current date into today
Say "Today's date is {today}"
"""#
            try sampleCode.write(to: mainFile, atomically: true, encoding: .utf8)

            let readmeFile = projectURL.appendingPathComponent("README.md")
            let readme = #"""
# \#(projectName)

A project written in **Sweasy** — The easiest, plain-English programming language powered by Swift.

## How to run:
```bash
sweasy run main.sweasy
```

## How to compile into a native binary:
```bash
sweasy build main.sweasy -o app
./app
```
"""#
            try readme.write(to: readmeFile, atomically: true, encoding: .utf8)

            print("✓ Created new Sweasy project '\(projectName)'!")
            print("  cd \(projectName)")
            print("  sweasy run main.sweasy")
        } catch {
            print("Error creating project: \(error.localizedDescription)")
            exit(1)
        }
    }

    static func handleExamples(arguments: [String]) {
        if arguments.isEmpty {
            print("Available Sweasy Built-in Examples:")
            for (key, item) in Examples.all.sorted(by: { $0.key < $1.key }) {
                print("  • \u{001B}[32m\(key)\u{001B}[0m: \(item.name) — \(item.description)")
            }
            print("\nRun an example with: sweasy examples <name> --run")
            print("Save an example with: sweasy examples <name> -o <filename.sweasy>")
            return
        }

        let exampleKey = arguments[0].lowercased()
        guard let example = Examples.all[exampleKey] else {
            print("Example '\(exampleKey)' not found.")
            print("Available examples: \(Examples.all.keys.sorted().joined(separator: ", "))")
            exit(1)
        }

        if arguments.contains("--run") {
            do {
                let compiler = Compiler()
                try compiler.run(source: example.code)
            } catch {
                print(error.localizedDescription)
                exit(1)
            }
            return
        }

        if let oIdx = arguments.firstIndex(of: "-o"), oIdx + 1 < arguments.count {
            let outPath = arguments[oIdx + 1]
            do {
                try example.code.write(toFile: outPath, atomically: true, encoding: .utf8)
                print("✓ Saved example '\(exampleKey)' to \(outPath)")
            } catch {
                print("Error saving example: \(error.localizedDescription)")
                exit(1)
            }
            return
        }

        // Print example code
        print(example.code)
    }

    static func printHelp() {
        print("""
\u{001B}[1mSweasy (Swift + Easy)\u{001B}[0m — Plain English Programming Language
Powered by Apple Swift 6

\u{001B}[1mUSAGE:\u{001B}[0m
  sweasy                        Start the interactive REPL
  sweasy run <file.sweasy>      Run a Sweasy source file directly
  sweasy build <file.sweasy>    Compile to a native standalone executable
  sweasy transpile <file.sweasy> Translate Sweasy code into clean Swift 6 code
  sweasy new <project-name>     Create a new Sweasy project
  sweasy examples               List or run built-in examples
  sweasy help                   Show this help message
  sweasy version                Show version information

\u{001B}[1mLANGUAGE CHEAT SHEET:\u{001B}[0m
  \u{001B}[36mDisplay & Output:\u{001B}[0m
    Say "Hello, World!"
    Show "Current score:", score
    Say "Hello, {name}!"           (String interpolation)

  \u{001B}[36mVariables & Math:\u{001B}[0m
    Set score to 100
    Let pi be 3.14159
    Increase score by 10
    Decrease lives by 1
    Set total to a plus b times 2

  \u{001B}[36mUser Input:\u{001B}[0m
    Ask user for name with "What is your name? "
    Ask user for age as integer with "How old are you? "

  \u{001B}[36mConditionals:\u{001B}[0m
    If score is greater than 50:
        Say "You passed!"
    Otherwise if score is 50:
        Say "Just made it!"
    Otherwise:
        Say "Try again!"
    End

  \u{001B}[36mLoops:\u{001B}[0m
    Repeat 5 times:
        Say "Counting..."
    End

    For each item in items:
        Say "Item:", item
    End

    While count is less than 10:
        Increase count by 1
    End

  \u{001B}[36mLists & Dictionaries:\u{001B}[0m
    Set fruits to ["apple", "banana"]
    Add "orange" to fruits
    Remove "banana" from fruits
    Sort fruits

  \u{001B}[36mFunctions:\u{001B}[0m
    Function greet with name:
        Say "Hello, " + name + "!"
    End
    Call greet with "Alice"

  \u{001B}[36mSuperpowers:\u{001B}[0m
    Get random number between 1 and 100 into secret
    Get current date into today
    Wait 2 seconds
    Write "hello" to file "test.txt"
    Read file "test.txt" into text
    Fetch text from url "https://apple.com" into html
""")
    }
}
