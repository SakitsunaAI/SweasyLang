import Foundation

public struct Examples {
    public static let hello = #"""
# -------------------------------------------------------------
# Hello World in Sweasy
# -------------------------------------------------------------

Say "Welcome to Sweasy!"
Say "The world's easiest programming language, powered by Swift."

Set name to "Explorer"
Let year be 2026

Say "Hello {name}, welcome to the year {year}!"

Get current date into today
Get current time into now
Say "Current Date: {today}"
Say "Current Time: {now}"
"""#

    public static let calculator = #"""
# -------------------------------------------------------------
# Natural English Calculator in Sweasy
# -------------------------------------------------------------

Set a to 25
Set b to 4

Say "Number A is", a
Say "Number B is", b

Set sum to a plus b
Set difference to a minus b
Set product to a times b
Set quotient to a divided by b
Set remainder to a modulo b

Say "{a} plus {b} is {sum}"
Say "{a} minus {b} is {difference}"
Say "{a} times {b} is {product}"
Say "{a} divided by {b} is {quotient}"
Say "{a} modulo {b} is {remainder}"

Set root to square root of 144
Say "Square root of 144 is {root}"
"""#

    public static let guessingGame = #"""
# -------------------------------------------------------------
# Number Guessing Game in Sweasy
# -------------------------------------------------------------

Say "=== Welcome to the Sweasy Guessing Game! ==="
Say "I am thinking of a number between 1 and 50."

Get random number between 1 and 50 into target
Set attempts to 0

Repeat:
    Ask user for guess as integer with "Enter your guess: "
    Increase attempts by 1

    If guess is equal to target:
        Say "🎉 Correct! You found the number in {attempts} attempts!"
        Break
    Otherwise if guess is less than target:
        Say "Too low! Aim higher."
    Otherwise:
        Say "Too high! Aim lower."
    End
End

Say "Thanks for playing!"
"""#

    public static let todoList = #"""
# -------------------------------------------------------------
# To-Do List Manager in Sweasy
# -------------------------------------------------------------

Set tasks to ["Learn Sweasy", "Build an iOS App", "Drink coffee"]

Say "Initial tasks:"
For each task in tasks:
    Say "•", task
End

Say ""
Say "Adding new task..."
Add "Walk the dog" to tasks

Say "Updated tasks:"
For each task in tasks:
    Say "•", task
End

Say ""
Say "Removing 'Drink coffee'..."
Remove "Drink coffee" from tasks

Say "Final tasks (sorted):"
Sort tasks
For each task in tasks:
    Say "✓", task
End
"""#

    public static let fileDemo = #"""
# -------------------------------------------------------------
# File Operations in Sweasy
# -------------------------------------------------------------

Set filename to "sweasy_note.txt"
Set content to "Sweasy makes coding feel like writing a story.\nPowered natively by Swift!"

Say "Writing text to {filename}..."
Write content to file filename

Check if file filename exists into exists
If exists is equal to true:
    Say "File created successfully!"
End

Say "Reading back file contents:"
Read file filename into fileData
Say "--- File Content Start ---"
Say fileData
Say "--- File Content End ---"

Say "Appending more text..."
Append "\nAdded another line seamlessly!" to file filename

Read file filename into updatedData
Say "Updated file:"
Say updatedData

Delete file filename
Say "Cleaned up temporary file."
"""#

    public static let all: [String: (name: String, description: String, code: String)] = [
        "hello": ("Hello World", "Basic output, variables and string interpolation", hello),
        "calculator": ("Calculator", "Math expressions written in plain English", calculator),
        "game": ("Guessing Game", "Interactive number guessing game with loops", guessingGame),
        "todo": ("To-Do List", "Lists, appending, removing, and sorting", todoList),
        "file": ("File Operations", "Writing, reading, and appending files", fileDemo)
    ]
}

