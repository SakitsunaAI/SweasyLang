# 🌟 Sweasy (Swift + Easy)
### *The World's Easiest Programming Language — Powered by Apple Swift*

> **Sweasy** is designed for humans. You don't write cryptic symbols, nested semicolons, or boilerplate syntax; you write **plain English sentences**. Behind the scenes, Sweasy transpiles your sentences into clean, type-safe **Apple Swift 6** and compiles them using `swiftc` into lightning-fast native executables.

---

## 🚀 Key Features

- **📖 100% Plain English Sentences**: Code reads like a story. Anyone who knows basic English can code immediately.
- **⚡ Swift 6 Powered**: Backed by the speed, safety, and modern runtime of Apple Swift.
- **🔨 Standalone Native Binaries**: Compile your English code into single native executables with `swiftc -O`.
- **💬 Interactive REPL**: Real-time terminal environment where you can type English sentences and see results instantly.
- **✨ Built-in Superpowers**: Out-of-the-box support for Date/Time, File I/O, Web Requests, Shell commands, Randomization, and Collections.
- **🪟 Seamless Swift Escape Hatch**: Need to call standard Swift APIs or Foundation? Just use `Swift:` blocks.

---

## 🛠️ Quick Installation

From the project root:

```bash
# Build the Sweasy compiler (in release mode)
swift build -c release

# (Optional) Link to /usr/local/bin for global access
sudo cp .build/release/sweasy /usr/local/bin/sweasy
```

Or run via the built local binary:
```bash
./bin/sweasy --help
```

---

## 🏁 Quick Start & Usage

### 1. Interactive REPL (Try it live!)
Run `sweasy` without arguments:
```bash
./bin/sweasy
```
```text
   ____                               
  / ___|_      _____  __ _ ___ _   _  
  \___ \ \ /\ / / _ \/ _` / __| | | | 
   ___) \ V  V /  __/ (_| \__ \ |_| | 
  |____/ \_/\_/ \___|\__,_|___/\__, | 
                               |___/  

Sweasy (Swift + Easy) — The World's Easiest Programming Language
Powered by Apple Swift 6

sweasy> Say "Hello, World!"
Hello, World!
sweasy> Set score to 100
sweasy> Increase score by 25
sweasy> Say "Final score: {score}"
Final score: 125
```

### 2. Run a Sweasy Script Directly
```bash
./bin/sweasy run Examples/hello.sweasy
```

### 3. Compile to a Native Standalone Executable
```bash
./bin/sweasy build Examples/calculator.sweasy -o calc
./calc
```

### 4. Inspect the Generated Swift Code
```bash
./bin/sweasy transpile Examples/hello.sweasy
```

---

## 📚 Language Reference & Syntax Cheat Sheet

### 1. Display & Printing
```sweasy
Say "Hello, World!"
Show "Current score is", score
Print "Welcome!"
Display "Game Over"

# String interpolation with {variable}
Set name to "Alice"
Say "Welcome, {name}!"
```

### 2. Variables & Constants
```sweasy
Set score to 100          # var score = 100
Let pi be 3.14159         # let pi = 3.14159
Remember name as "Bob"    # var name = "Bob"
Define version as "1.0"   # let version = "1.0"

Change score to 200       # score = 200
```

### 3. English Math & Mutations
```sweasy
Increase score by 10      # score += 10
Decrease lives by 1       # lives -= 1
Multiply power by 2       # power *= 2
Divide total by 4         # total /= 4

Set total to a plus b
Set difference to a minus b
Set product to a times b
Set quotient to a divided by b
Set rem to a modulo b

Set root to square root of 144
Set rounded to round 3.7
```

### 4. Asking User Input
```sweasy
Ask user for name with "What is your name? "
Ask user for age as integer with "How old are you? "
Ask user for price as number with "Enter item price: "
```

### 5. Conditionals (Natural Comparisons)
```sweasy
If score is greater than 90:
    Say "Grade A!"
Otherwise if score is at least 60:
    Say "You passed!"
Otherwise:
    Say "Try again!"
End

# Inline single-line if:
If lives is 0 then say "Game Over!"
```

Supported English comparisons:
- `is equal to`, `equals`, `is` (`==`)
- `is not equal to`, `does not equal`, `is not` (`!=`)
- `is greater than` (`>`)
- `is less than` (`<`)
- `is greater than or equal to`, `is at least` (`>=`)
- `is less than or equal to`, `is at most` (`<=`)
- `is empty`, `is not empty`
- `and`, `or`, `not`

### 6. Loops
```sweasy
# Repeat N times
Repeat 5 times:
    Say "Hello!"
End

# Repeat range with index
Repeat from 1 to 5 as i:
    Say "Step number {i}"
End

# For each item in collection
For each fruit in fruits:
    Say "I like {fruit}"
End

# While condition
While count is less than 10:
    Increase count by 1
End

# Infinite loop with break
Repeat:
    If answer is "quit" then break
End
```

### 7. Collections (Lists & Dictionaries)
```sweasy
Set fruits to ["Apple", "Banana", "Cherry"]

Add "Orange" to fruits
Remove "Banana" from fruits
Remove item at index 0 from fruits
Sort fruits
Reverse fruits

Say "Count:", length of fruits
Say "First:", first item of fruits
Say "Last:", last item of fruits
```

### 8. Functions
```sweasy
Function greet with name:
    Say "Hello, {name}!"
End

Function multiply with a as Int, b as Int returning Int:
    Return a times b
End

Call greet with "Alice"
Set result to multiply(6, 7)
```

### 9. Standard Library Superpowers
```sweasy
# Date & Time
Get current date into today
Get current time into now

# Random numbers
Get random number between 1 and 100 into roll
Get random decimal between 0.0 and 1.0 into factor

# Timing
Wait 2 seconds

# File Operations
Write "Hello World" to file "message.txt"
Append "\nNext line" to file "message.txt"
Read file "message.txt" into content
Check if file "message.txt" exists into exists
Delete file "message.txt"

# Web / HTTP
Fetch text from url "https://api.github.com" into response

# Shell
Run shell command "uname -m" into machineArchitecture
```

### 10. Native Swift Escape Hatch
```sweasy
Swift:
    let date = Date()
    print("Direct Swift execution: \(date)")
End
```

---

## 📂 Project Architecture

```
Sweasy-Lang/
├── Package.swift               # Swift Package definition
├── bin/
│   └── sweasy                  # Release executable binary
├── Sources/sweasy/
│   ├── sweasy.swift            # CLI entrypoint (run, build, transpile, repl)
│   ├── Models.swift            # AST Nodes and data models
│   ├── Lexer.swift / ExpParser # English natural language expression transformer
│   ├── Parser.swift            # English sentence parser
│   ├── Transpiler.swift        # AST to Swift 6 code generator
│   ├── Runtime.swift           # Embedded runtime library in transpiled Swift
│   ├── Compiler.swift          # Bridge to swiftc and swift runtime
│   ├── REPL.swift              # Interactive English terminal loop
│   └── Examples.swift          # Built-in sample programs
└── Examples/                   # Ready-to-run .sweasy source files
    ├── hello.sweasy
    ├── calculator.sweasy
    ├── guessing_game.sweasy
    ├── todo_list.sweasy
    ├── file_demo.sweasy
    └── functions.sweasy
```

---

## 🧪 Running the Examples

Try running any of the provided examples:

```bash
# Hello World
./bin/sweasy run Examples/hello.sweasy

# Natural English Calculator
./bin/sweasy run Examples/calculator.sweasy

# Guessing Game
./bin/sweasy run Examples/guessing_game.sweasy

# To-Do List
./bin/sweasy run Examples/todo_list.sweasy

# File I/O
./bin/sweasy run Examples/file_demo.sweasy

# Functions
./bin/sweasy run Examples/functions.sweasy
```

