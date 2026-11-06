import Foundation

/// Parses lines of Sweasy natural English source code into an Abstract Syntax Tree (AST).
public final class Parser {
    public struct SourceLine {
        public let line: Int
        public let text: String
    }

    private var lines: [SourceLine] = []
    private var index: Int = 0

    public init() {}

    /// Strips comments and trailing punctuation while preserving string literals
    public static func preprocessLine(_ raw: String) -> String {
        var result = ""
        var inString = false
        var quoteChar: Character = "\""
        var isEscaped = false

        let chars = Array(raw)
        var i = 0

        while i < chars.count {
            let c = chars[i]

            if inString {
                result.append(c)
                if isEscaped {
                    isEscaped = false
                } else if c == "\\" {
                    isEscaped = true
                } else if c == quoteChar {
                    inString = false
                }
                i += 1
            } else {
                // Check comment starters: #, //, Note:, Remark:
                if c == "#" {
                    break
                }
                if c == "/" && i + 1 < chars.count && chars[i + 1] == "/" {
                    break
                }
                if c == "\"" || c == "'" {
                    inString = true
                    quoteChar = c
                    result.append(c)
                    i += 1
                } else {
                    result.append(c)
                    i += 1
                }
            }
        }

        var trimmed = result.trimmingCharacters(in: .whitespaces)

        // Strip whole-line "Note:" or "Remark:" comments
        let lower = trimmed.lowercased()
        if lower.hasPrefix("note:") || lower.hasPrefix("remark:") {
            return ""
        }

        // Strip trailing period if not inside quotes or decimal
        if trimmed.hasSuffix(".") && !trimmed.hasSuffix("..") {
            trimmed.removeLast()
            trimmed = trimmed.trimmingCharacters(in: .whitespaces)
        }

        return trimmed
    }

    public func parse(source: String) throws -> Program {
        let rawLines = source.components(separatedBy: .newlines)
        self.lines = []
        for (idx, raw) in rawLines.enumerated() {
            let processed = Parser.preprocessLine(raw)
            if !processed.isEmpty {
                self.lines.append(SourceLine(line: idx + 1, text: processed))
            }
        }
        self.index = 0

        var statements: [Statement] = []
        while index < lines.count {
            if let stmt = try parseStatement() {
                statements.append(stmt)
            }
        }

        return Program(statements: statements)
    }

    private func peek() -> SourceLine? {
        guard index < lines.count else { return nil }
        return lines[index]
    }

    private func advance() -> SourceLine? {
        guard index < lines.count else { return nil }
        let l = lines[index]
        index += 1
        return l
    }

    // MARK: - Block & Statement Parsing

    private func parseStatement() throws -> Statement? {
        guard let current = peek() else { return nil }
        let text = current.text
        let lineNum = current.line

        // Check if block termination
        if isBlockEnd(text) {
            return nil
        }

        // 1. Raw Swift Multi-line Block
        if text.lowercased() == "swift:" || text.lowercased() == "swift" {
            _ = advance()
            var codeLines: [String] = []
            while let next = peek(), !isBlockEnd(next.text) {
                _ = advance()
                codeLines.append(next.text)
            }
            if let end = peek(), isBlockEnd(end.text) {
                _ = advance()
            }
            return .rawSwift(codeLines.joined(separator: "\n"))
        }

        // 2. Raw Swift Single-line
        if text.lowercased().hasPrefix("swift:") {
            _ = advance()
            let code = String(text.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            return .rawSwift(code)
        }

        // 3. Conditionals: If ...
        if text.lowercased().hasPrefix("if ") {
            return try parseIfStatement()
        }

        // 4. Loops: Repeat ...
        if text.lowercased().hasPrefix("repeat") {
            return try parseRepeatStatement()
        }

        // 5. Loops: For each ...
        if text.lowercased().hasPrefix("for each ") {
            return try parseForEachStatement()
        }

        // 6. Loops: While ...
        if text.lowercased().hasPrefix("while ") {
            return try parseWhileStatement()
        }

        // 7. Functions: Function ... or To ...
        if text.lowercased().hasPrefix("function ") || text.lowercased().hasPrefix("to ") {
            return try parseFunctionStatement()
        }

        // Single-line Statements
        _ = advance()
        return try parseSingleLine(text, line: lineNum)
    }

    private func isBlockEnd(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: CharacterSet(charactersIn: " .:")).lowercased()
        return t == "end" ||
               t == "end if" ||
               t == "end repeat" ||
               t == "end while" ||
               t == "end for" ||
               t == "end function" ||
               t == "end to" ||
               t == "end swift" ||
               t.hasPrefix("otherwise") ||
               t.hasPrefix("else")
    }

    private func isStrictBlockEnd(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: CharacterSet(charactersIn: " .:")).lowercased()
        return t == "end" ||
               t == "end if" ||
               t == "end repeat" ||
               t == "end while" ||
               t == "end for" ||
               t == "end function" ||
               t == "end to" ||
               t == "end swift"
    }

    private func parseBlockStatements() throws -> [Statement] {
        var statements: [Statement] = []
        while let current = peek() {
            if isBlockEnd(current.text) {
                break
            }
            if let stmt = try parseStatement() {
                statements.append(stmt)
            }
        }
        return statements
    }

    // MARK: - If Statement
    private func parseIfStatement() throws -> Statement {
        guard let current = advance() else {
            throw SweasyError("Unexpected end of input in If statement")
        }
        var text = current.text
        if text.hasSuffix(":") {
            text.removeLast()
        }

        // Check if inline "If <cond> then <stmt>"
        if let thenRange = text.range(of: " then ", options: .caseInsensitive) {
            let condStr = String(text[text.index(text.startIndex, offsetBy: 3)..<thenRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let stmtStr = String(text[thenRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            let condExpr = ExpressionParser.transformExpression(condStr)
            guard let thenStmt = try parseSingleLine(stmtStr, line: current.line) else {
                throw SweasyError("Invalid statement after 'then'", line: current.line)
            }
            return .ifCondition(
                condition: .rawSwift(condExpr),
                thenBranch: [thenStmt],
                elseIfs: [],
                elseBranch: nil
            )
        }

        // Block If
        let condStr = String(text.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        let condExpr = ExpressionParser.transformExpression(condStr)

        let thenBranch = try parseBlockStatements()

        var elseIfs: [ElseIfClause] = []
        var elseBranch: [Statement]? = nil

        while let next = peek() {
            let nextText = next.text.trimmingCharacters(in: CharacterSet(charactersIn: " .:")).lowercased()

            if nextText.hasPrefix("otherwise if ") || nextText.hasPrefix("else if ") {
                _ = advance()
                let prefixLen = nextText.hasPrefix("otherwise if ") ? 13 : 8
                var nextLine = next.text
                if nextLine.hasSuffix(":") { nextLine.removeLast() }
                let subCondStr = String(nextLine.dropFirst(prefixLen)).trimmingCharacters(in: .whitespaces)
                let subCondExpr = ExpressionParser.transformExpression(subCondStr)
                let subBranch = try parseBlockStatements()
                elseIfs.append(ElseIfClause(condition: .rawSwift(subCondExpr), body: subBranch))
            } else if nextText == "otherwise" || nextText == "else" {
                _ = advance()
                elseBranch = try parseBlockStatements()
            } else if isStrictBlockEnd(next.text) {
                _ = advance()
                break
            } else {
                break
            }
        }

        return .ifCondition(
            condition: .rawSwift(condExpr),
            thenBranch: thenBranch,
            elseIfs: elseIfs,
            elseBranch: elseBranch
        )
    }

    // MARK: - Repeat Statement
    private func parseRepeatStatement() throws -> Statement {
        guard let current = advance() else {
            throw SweasyError("Unexpected end of input in Repeat statement")
        }
        var text = current.text
        if text.hasSuffix(":") {
            text.removeLast()
        }
        let lower = text.lowercased()

        // 1. Repeat N times
        if lower.hasPrefix("repeat ") && lower.hasSuffix(" times") {
            let inner = String(text.dropFirst(7).dropLast(6)).trimmingCharacters(in: .whitespaces)
            let timesExpr = ExpressionParser.transformExpression(inner)
            let body = try parseBlockStatements()
            if let end = peek(), isStrictBlockEnd(end.text) { _ = advance() }
            return .repeatCount(times: .rawSwift(timesExpr), body: body)
        }

        // 2. Repeat from <start> to <end> as <var>
        if lower.hasPrefix("repeat from ") && lower.contains(" to ") && lower.contains(" as ") {
            let rest = String(text.dropFirst(12)) // drop "repeat from "
            if let toRange = rest.range(of: " to ", options: .caseInsensitive),
               let asRange = rest.range(of: " as ", options: .caseInsensitive) {
                let startStr = String(rest[..<toRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let endStr = String(rest[toRange.upperBound..<asRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let varName = String(rest[asRange.upperBound...]).trimmingCharacters(in: .whitespaces)

                let startExpr = ExpressionParser.transformExpression(startStr)
                let endExpr = ExpressionParser.transformExpression(endStr)

                let body = try parseBlockStatements()
                if let end = peek(), isStrictBlockEnd(end.text) { _ = advance() }
                return .repeatRange(variable: varName, from: .rawSwift(startExpr), to: .rawSwift(endExpr), body: body)
            }
        }

        // 3. Repeat: (infinite loop)
        if lower == "repeat" {
            let body = try parseBlockStatements()
            if let end = peek(), isStrictBlockEnd(end.text) { _ = advance() }
            return .repeatInfinite(body: body)
        }

        throw SweasyError("Unrecognized Repeat statement: '\(current.text)'", line: current.line)
    }

    // MARK: - For Each Statement
    private func parseForEachStatement() throws -> Statement {
        guard let current = advance() else {
            throw SweasyError("Unexpected end of input in For Each statement")
        }
        var text = current.text
        if text.hasSuffix(":") { text.removeLast() }
        let rest = String(text.dropFirst(9)).trimmingCharacters(in: .whitespaces) // drop "for each "

        guard let inRange = rest.range(of: " in ", options: .caseInsensitive) else {
            throw SweasyError("Expected 'in' in For Each statement: '\(current.text)'", line: current.line)
        }

        let varName = String(rest[..<inRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        let collStr = String(rest[inRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        let collExpr = ExpressionParser.transformExpression(collStr)

        let body = try parseBlockStatements()
        if let end = peek(), isStrictBlockEnd(end.text) { _ = advance() }

        return .forEach(variable: varName, collection: .rawSwift(collExpr), body: body)
    }

    // MARK: - While Statement
    private func parseWhileStatement() throws -> Statement {
        guard let current = advance() else {
            throw SweasyError("Unexpected end of input in While statement")
        }
        var text = current.text
        if text.hasSuffix(":") { text.removeLast() }
        let condStr = String(text.dropFirst(6)).trimmingCharacters(in: .whitespaces) // drop "while "
        let condExpr = ExpressionParser.transformExpression(condStr)

        let body = try parseBlockStatements()
        if let end = peek(), isStrictBlockEnd(end.text) { _ = advance() }

        return .whileLoop(condition: .rawSwift(condExpr), body: body)
    }

    // MARK: - Function Definition Statement
    private func parseFunctionStatement() throws -> Statement {
        guard let current = advance() else {
            throw SweasyError("Unexpected end of input in Function statement")
        }
        var text = current.text
        if text.hasSuffix(":") { text.removeLast() }

        var header = text
        if header.lowercased().hasPrefix("function ") {
            header = String(header.dropFirst(9)).trimmingCharacters(in: .whitespaces)
        } else if header.lowercased().hasPrefix("to ") {
            header = String(header.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        }

        var returnType: String? = nil
        if let retRange = header.range(of: " returning ", options: .caseInsensitive) {
            let retStr = String(header[retRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            returnType = normalizeTypeName(retStr)
            header = String(header[..<retRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        } else if let arrowRange = header.range(of: "->") {
            let retStr = String(header[arrowRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            returnType = normalizeTypeName(retStr)
            header = String(header[..<arrowRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }

        var funcName = header
        var params: [FunctionParameter] = []

        if let withRange = header.range(of: " with ", options: .caseInsensitive) {
            funcName = String(header[..<withRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let paramsStr = String(header[withRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            let rawParts = paramsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            for part in rawParts {
                params.append(parseParameter(part))
            }
        }

        let normalizedName = funcName.replacingOccurrences(of: " ", with: "_")
        let body = try parseBlockStatements()
        if let end = peek(), isStrictBlockEnd(end.text) { _ = advance() }

        return .functionDefinition(name: normalizedName, parameters: params, returnType: returnType, body: body)
    }

    private func parseParameter(_ raw: String) -> FunctionParameter {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if let asRange = trimmed.range(of: " as ", options: .caseInsensitive) {
            let name = String(trimmed[..<asRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let typeStr = String(trimmed[asRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            return FunctionParameter(name: name, typeName: normalizeTypeName(typeStr))
        }
        if let colonRange = trimmed.range(of: ":") {
            let name = String(trimmed[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let typeStr = String(trimmed[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            return FunctionParameter(name: name, typeName: normalizeTypeName(typeStr))
        }
        return FunctionParameter(name: trimmed, typeName: "Any")
    }

    private func normalizeTypeName(_ raw: String) -> String {
        let lower = raw.trimmingCharacters(in: .whitespaces).lowercased()
        switch lower {
        case "number", "decimal": return "Double"
        case "integer", "int": return "Int"
        case "text", "string": return "String"
        case "boolean", "bool": return "Bool"
        case "list": return "[Any]"
        default: return raw.trimmingCharacters(in: .whitespaces)
        }
    }

    // MARK: - Single Line Statement Parser
    public func parseSingleLine(_ line: String, line number: Int) throws -> Statement? {
        var text = line.trimmingCharacters(in: .whitespaces)
        if text.hasSuffix(":") { text.removeLast() }
        let lower = text.lowercased()

        // 1. Output: Say / Show / Print / Display
        for verb in ["say", "show", "print", "display"] {
            if lower.hasPrefix("\(verb) ") {
                let rest = String(text.dropFirst(verb.count + 1)).trimmingCharacters(in: .whitespaces)
                let parts = ExpressionParser.splitCommaSeparatedExpressions(rest)
                let exprs = parts.map { Expression.rawSwift(ExpressionParser.transformExpression($0)) }
                return .say(exprs)
            }
        }

        // 2. Variable Declarations
        // "Set <name> to <expr>"
        if lower.hasPrefix("set ") {
            let rest = String(text.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            if let toRange = rest.range(of: " to ", options: .caseInsensitive) {
                let name = String(rest[..<toRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[toRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .setVariable(name: name, value: .rawSwift(expr), isConstant: false)
            }
        }

        // "Let <name> be <expr>"
        if lower.hasPrefix("let ") {
            let rest = String(text.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            if let beRange = rest.range(of: " be ", options: .caseInsensitive) {
                let name = String(rest[..<beRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[beRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .setVariable(name: name, value: .rawSwift(expr), isConstant: true)
            }
        }

        // "Remember <name> as <expr>"
        if lower.hasPrefix("remember ") {
            let rest = String(text.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            if let asRange = rest.range(of: " as ", options: .caseInsensitive) {
                let name = String(rest[..<asRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[asRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .setVariable(name: name, value: .rawSwift(expr), isConstant: false)
            }
        }

        // "Define <name> as <expr>"
        if lower.hasPrefix("define ") {
            let rest = String(text.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            if let asRange = rest.range(of: " as ", options: .caseInsensitive) {
                let name = String(rest[..<asRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[asRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .setVariable(name: name, value: .rawSwift(expr), isConstant: true)
            }
        }

        // "Change <name> to <expr>"
        if lower.hasPrefix("change ") {
            let rest = String(text.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            if let toRange = rest.range(of: " to ", options: .caseInsensitive) {
                let name = String(rest[..<toRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[toRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .changeVariable(name: name, value: .rawSwift(expr))
            }
        }

        // 3. Mutations
        // "Increase <name> by <expr>"
        if lower.hasPrefix("increase ") {
            let rest = String(text.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            if let byRange = rest.range(of: " by ", options: .caseInsensitive) {
                let name = String(rest[..<byRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[byRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .mutateVariable(name: name, op: .increase, value: .rawSwift(expr))
            }
        }

        // "Decrease <name> by <expr>"
        if lower.hasPrefix("decrease ") {
            let rest = String(text.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            if let byRange = rest.range(of: " by ", options: .caseInsensitive) {
                let name = String(rest[..<byRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[byRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .mutateVariable(name: name, op: .decrease, value: .rawSwift(expr))
            }
        }

        // "Multiply <name> by <expr>"
        if lower.hasPrefix("multiply ") {
            let rest = String(text.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            if let byRange = rest.range(of: " by ", options: .caseInsensitive) {
                let name = String(rest[..<byRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[byRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .mutateVariable(name: name, op: .multiply, value: .rawSwift(expr))
            }
        }

        // "Divide <name> by <expr>"
        if lower.hasPrefix("divide ") {
            let rest = String(text.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            if let byRange = rest.range(of: " by ", options: .caseInsensitive) {
                let name = String(rest[..<byRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(rest[byRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let expr = ExpressionParser.transformExpression(valStr)
                return .mutateVariable(name: name, op: .divide, value: .rawSwift(expr))
            }
        }

        // 4. User Input
        // "Ask user for <name> as number with <prompt>"
        if lower.hasPrefix("ask user for ") {
            let rest = String(text.dropFirst(13)).trimmingCharacters(in: .whitespaces)
            if let withRange = rest.range(of: " with ", options: .caseInsensitive) {
                let left = String(rest[..<withRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let promptStr = String(rest[withRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let promptExpr = ExpressionParser.transformExpression(promptStr)

                if left.lowercased().hasSuffix(" as number") {
                    let name = String(left.dropLast(10)).trimmingCharacters(in: .whitespaces)
                    return .askUser(target: name, prompt: .rawSwift(promptExpr), type: .number)
                } else if left.lowercased().hasSuffix(" as integer") {
                    let name = String(left.dropLast(11)).trimmingCharacters(in: .whitespaces)
                    return .askUser(target: name, prompt: .rawSwift(promptExpr), type: .integer)
                } else {
                    return .askUser(target: left, prompt: .rawSwift(promptExpr), type: .string)
                }
            }
        }

        // "Ask <prompt> into <name>"
        if lower.hasPrefix("ask ") && lower.contains(" into ") {
            let rest = String(text.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            if let intoRange = rest.range(of: " into ", options: .caseInsensitive) {
                let promptStr = String(rest[..<intoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let target = String(rest[intoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let promptExpr = ExpressionParser.transformExpression(promptStr)
                return .askUser(target: target, prompt: .rawSwift(promptExpr), type: .string)
            }
        }

        // 5. Random Numbers
        // "Get random number between <min> and <max> into <target>"
        if lower.hasPrefix("get random number between ") && lower.contains(" and ") && lower.contains(" into ") {
            let rest = String(text.dropFirst(26))
            if let andRange = rest.range(of: " and ", options: .caseInsensitive),
               let intoRange = rest.range(of: " into ", options: .caseInsensitive) {
                let minStr = String(rest[..<andRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let maxStr = String(rest[andRange.upperBound..<intoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let target = String(rest[intoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let minExpr = ExpressionParser.transformExpression(minStr)
                let maxExpr = ExpressionParser.transformExpression(maxStr)
                return .getRandom(from: .rawSwift(minExpr), to: .rawSwift(maxExpr), target: target, isDouble: false)
            }
        }

        // "Get random decimal between <min> and <max> into <target>"
        if lower.hasPrefix("get random decimal between ") && lower.contains(" and ") && lower.contains(" into ") {
            let rest = String(text.dropFirst(27))
            if let andRange = rest.range(of: " and ", options: .caseInsensitive),
               let intoRange = rest.range(of: " into ", options: .caseInsensitive) {
                let minStr = String(rest[..<andRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let maxStr = String(rest[andRange.upperBound..<intoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let target = String(rest[intoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let minExpr = ExpressionParser.transformExpression(minStr)
                let maxExpr = ExpressionParser.transformExpression(maxStr)
                return .getRandom(from: .rawSwift(minExpr), to: .rawSwift(maxExpr), target: target, isDouble: true)
            }
        }

        // 6. Date & Time
        // "Get current date into <target>"
        if lower.hasPrefix("get current date into ") {
            let target = String(text.dropFirst(22)).trimmingCharacters(in: .whitespaces)
            return .getDate(target: target)
        }
        // "Get current time into <target>"
        if lower.hasPrefix("get current time into ") {
            let target = String(text.dropFirst(22)).trimmingCharacters(in: .whitespaces)
            return .getTime(target: target)
        }

        // 7. Timing & Sleep
        // "Wait <expr> seconds" or "Sleep <expr> seconds"
        for verb in ["wait", "sleep"] {
            if lower.hasPrefix("\(verb) ") {
                var inner = String(text.dropFirst(verb.count + 1)).trimmingCharacters(in: .whitespaces)
                if inner.lowercased().hasSuffix(" seconds") {
                    inner = String(inner.dropLast(8)).trimmingCharacters(in: .whitespaces)
                } else if inner.lowercased().hasSuffix(" second") {
                    inner = String(inner.dropLast(7)).trimmingCharacters(in: .whitespaces)
                }
                let expr = ExpressionParser.transformExpression(inner)
                return .wait(seconds: .rawSwift(expr))
            }
        }

        // 8. File I/O
        // "Write <content> to file <path>"
        if lower.hasPrefix("write ") && lower.contains(" to file ") {
            let rest = String(text.dropFirst(6))
            if let toRange = rest.range(of: " to file ", options: .caseInsensitive) {
                let contentStr = String(rest[..<toRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let pathStr = String(rest[toRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                return .writeFile(
                    content: .rawSwift(ExpressionParser.transformExpression(contentStr)),
                    path: .rawSwift(ExpressionParser.transformExpression(pathStr))
                )
            }
        }

        // "Append <content> to file <path>"
        if lower.hasPrefix("append ") && lower.contains(" to file ") {
            let rest = String(text.dropFirst(7))
            if let toRange = rest.range(of: " to file ", options: .caseInsensitive) {
                let contentStr = String(rest[..<toRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let pathStr = String(rest[toRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                return .appendFile(
                    content: .rawSwift(ExpressionParser.transformExpression(contentStr)),
                    path: .rawSwift(ExpressionParser.transformExpression(pathStr))
                )
            }
        }

        // "Read file <path> into <target>"
        if lower.hasPrefix("read file ") && lower.contains(" into ") {
            let rest = String(text.dropFirst(10))
            if let intoRange = rest.range(of: " into ", options: .caseInsensitive) {
                let pathStr = String(rest[..<intoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let target = String(rest[intoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                return .readFile(
                    path: .rawSwift(ExpressionParser.transformExpression(pathStr)),
                    target: target
                )
            }
        }

        // "Check if file <path> exists into <target>"
        if lower.hasPrefix("check if file ") && lower.contains(" exists into ") {
            let rest = String(text.dropFirst(14))
            if let intoRange = rest.range(of: " exists into ", options: .caseInsensitive) {
                let pathStr = String(rest[..<intoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let target = String(rest[intoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                return .checkFileExists(
                    path: .rawSwift(ExpressionParser.transformExpression(pathStr)),
                    target: target
                )
            }
        }

        // "Delete file <path>"
        if lower.hasPrefix("delete file ") {
            let pathStr = String(text.dropFirst(12)).trimmingCharacters(in: .whitespaces)
            return .deleteFile(path: .rawSwift(ExpressionParser.transformExpression(pathStr)))
        }

        // 9. Web / Network
        // "Fetch text from url <url> into <target>"
        if lower.hasPrefix("fetch text from url ") && lower.contains(" into ") {
            let rest = String(text.dropFirst(20))
            if let intoRange = rest.range(of: " into ", options: .caseInsensitive) {
                let urlStr = String(rest[..<intoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let target = String(rest[intoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                return .fetchURL(
                    url: .rawSwift(ExpressionParser.transformExpression(urlStr)),
                    target: target
                )
            }
        }

        // 10. Shell Command
        // "Run shell command <cmd> into <target>"
        if lower.hasPrefix("run shell command ") && lower.contains(" into ") {
            let rest = String(text.dropFirst(18))
            if let intoRange = rest.range(of: " into ", options: .caseInsensitive) {
                let cmdStr = String(rest[..<intoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let target = String(rest[intoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                return .shellCommand(
                    command: .rawSwift(ExpressionParser.transformExpression(cmdStr)),
                    target: target
                )
            }
        }

        // 11. Collections
        // "Add <expr> to <list>"
        if lower.hasPrefix("add ") && lower.contains(" to ") {
            let rest = String(text.dropFirst(4))
            if let toRange = rest.range(of: " to ", options: .caseInsensitive) {
                let itemStr = String(rest[..<toRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let listName = String(rest[toRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let itemExpr = ExpressionParser.transformExpression(itemStr)
                return .listAdd(item: .rawSwift(itemExpr), list: listName)
            }
        }

        // "Remove item at index <index> from <list>"
        if lower.hasPrefix("remove item at index ") && lower.contains(" from ") {
            let rest = String(text.dropFirst(21))
            if let fromRange = rest.range(of: " from ", options: .caseInsensitive) {
                let idxStr = String(rest[..<fromRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let listName = String(rest[fromRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let idxExpr = ExpressionParser.transformExpression(idxStr)
                return .listRemoveAt(index: .rawSwift(idxExpr), list: listName)
            }
        }

        // "Remove <item> from <list>"
        if lower.hasPrefix("remove ") && lower.contains(" from ") {
            let rest = String(text.dropFirst(7))
            if let fromRange = rest.range(of: " from ", options: .caseInsensitive) {
                let itemStr = String(rest[..<fromRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let listName = String(rest[fromRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let itemExpr = ExpressionParser.transformExpression(itemStr)
                return .listRemove(item: .rawSwift(itemExpr), list: listName)
            }
        }

        // "Clear <list>"
        if lower.hasPrefix("clear ") {
            let listName = String(text.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            return .listClear(list: listName)
        }

        // "Sort <list>"
        if lower.hasPrefix("sort ") {
            let listName = String(text.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            return .listSort(list: listName)
        }

        // "Reverse <list>"
        if lower.hasPrefix("reverse ") {
            let listName = String(text.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            return .listReverse(list: listName)
        }

        // 12. Flow Control
        if lower == "break" || lower == "break out of loop" {
            return .breakLoop
        }
        if lower == "continue" || lower == "continue to next" {
            return .continueLoop
        }
        if lower == "stop program" || lower == "exit" || lower == "stop" {
            return .exitProgram
        }

        // Return
        if lower == "return" {
            return .returnStatement(nil)
        }
        if lower.hasPrefix("return ") {
            let retStr = String(text.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            let expr = ExpressionParser.transformExpression(retStr)
            return .returnStatement(.rawSwift(expr))
        }

        // Call <func> with <args>
        if lower.hasPrefix("call ") {
            let rest = String(text.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            var funcName = rest
            var args: [Expression] = []
            if let withRange = rest.range(of: " with ", options: .caseInsensitive) {
                funcName = String(rest[..<withRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let argsStr = String(rest[withRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let parts = ExpressionParser.splitCommaSeparatedExpressions(argsStr)
                args = parts.map { .rawSwift(ExpressionParser.transformExpression($0)) }
            }
            let normalized = funcName.replacingOccurrences(of: " ", with: "_")
            return .functionCall(name: normalized, arguments: args)
        }

        // Assignment: <var> = <expr>
        if let eqRange = text.range(of: " = ") {
            let name = String(text[..<eqRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let valStr = String(text[eqRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            let expr = ExpressionParser.transformExpression(valStr)
            return .changeVariable(name: name, value: .rawSwift(expr))
        }

        // Fallback: Expression statement (e.g. func call or raw Swift expression)
        let expr = ExpressionParser.transformExpression(text)
        return .expressionStatement(.rawSwift(expr))
    }
}
