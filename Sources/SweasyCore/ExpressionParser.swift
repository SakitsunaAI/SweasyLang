import Foundation

/// Handles parsing and transforming English expressions into Swift expressions,
/// safely handling string literals, interpolation, and natural language phrases.
public struct ExpressionParser {

    /// Replaces `{variable}` inside string literals with `\(variable)` for Swift interpolation.
    public static func transformStringLiteral(_ text: String) -> String {
        guard text.hasPrefix("\"") && text.hasSuffix("\"") && text.count >= 2 else {
            return text
        }
        let inner = String(text.dropFirst().dropLast())
        var result = "\""
        var i = inner.startIndex

        while i < inner.endIndex {
            if inner[i] == "{" {
                // Check if escaped: "\{"
                if i > inner.startIndex && inner[inner.index(before: i)] == "\\" {
                    result.append(inner[i])
                    i = inner.index(after: i)
                    continue
                }
                // Find closing '}'
                if let closeIndex = inner[i...].firstIndex(of: "}") {
                    let exprRange = inner.index(after: i)..<closeIndex
                    let expr = String(inner[exprRange]).trimmingCharacters(in: .whitespaces)
                    let translatedExpr = transformExpression(expr)
                    result.append("\\(\(translatedExpr))")
                    i = inner.index(after: closeIndex)
                    continue
                }
            }
            result.append(inner[i])
            i = inner.index(after: i)
        }

        result.append("\"")
        return result
    }

    /// Segments an expression into string literals and non-string code chunks
    public static func segmentExpression(_ raw: String) -> [(isString: Bool, text: String)] {
        var segments: [(isString: Bool, text: String)] = []
        var current = ""
        var inString = false
        var isEscaped = false
        var quoteChar: Character = "\""

        for char in raw {
            if inString {
                current.append(char)
                if isEscaped {
                    isEscaped = false
                } else if char == "\\" {
                    isEscaped = true
                } else if char == quoteChar {
                    inString = false
                    segments.append((isString: true, text: current))
                    current = ""
                }
            } else {
                if char == "\"" || char == "'" {
                    if !current.isEmpty {
                        segments.append((isString: false, text: current))
                        current = ""
                    }
                    inString = true
                    quoteChar = char
                    current.append("\"") // Normalize to double quotes
                } else {
                    current.append(char)
                }
            }
        }

        if !current.isEmpty {
            segments.append((isString: inString, text: current))
        }

        return segments
    }

    /// Transforms an English expression into Swift expression syntax
    public static func transformExpression(_ raw: String) -> String {
        let segments = segmentExpression(raw.trimmingCharacters(in: .whitespaces))
        var result = ""

        for seg in segments {
            if seg.isString {
                result.append(transformStringLiteral(seg.text))
            } else {
                result.append(transformCodeChunk(seg.text))
            }
        }

        return result
    }

    /// Transforms a non-string code chunk from English syntax to Swift syntax
    private static func transformCodeChunk(_ chunk: String) -> String {
        var text = chunk.trimmingCharacters(in: .whitespaces)

        // Special English Prefix Patterns
        text = replacePrefixPattern(text, prefix: "square root of ", replaceWith: "sqrt(Double(", suffix: "))")
        text = replacePrefixPattern(text, prefix: "absolute value of ", replaceWith: "abs(", suffix: ")")
        text = replacePrefixPattern(text, prefix: "round ", replaceWith: "round(Double(", suffix: "))")
        text = replacePrefixPattern(text, prefix: "length of ", replaceWith: "_sweasy_length(", suffix: ")")
        text = replacePrefixPattern(text, prefix: "first item of ", replaceWith: "_sweasy_first(", suffix: ")")
        text = replacePrefixPattern(text, prefix: "last item of ", replaceWith: "_sweasy_last(", suffix: ")")
        text = replacePrefixPattern(text, prefix: "uppercase of ", replaceWith: "_sweasy_uppercase(", suffix: ")")
        text = replacePrefixPattern(text, prefix: "lowercase of ", replaceWith: "_sweasy_lowercase(", suffix: ")")

        // Postfix conditions
        text = replacePattern(text, pattern: "(\\S+)\\s+is not empty\\b", replacement: "(!$1.isEmpty)")
        text = replacePattern(text, pattern: "(\\S+)\\s+is empty\\b", replacement: "$1.isEmpty")

        // Infix operators (ordered from longest to shortest)
        let infixReplacements: [(phrase: String, op: String)] = [
            ("is greater than or equal to", ">="),
            ("is less than or equal to", "<="),
            ("is not equal to", "!="),
            ("does not equal", "!="),
            ("is greater than", ">"),
            ("is less than", "<"),
            ("is at least", ">="),
            ("is at most", "<="),
            ("is equal to", "=="),
            ("is not", "!="),
            ("equals", "=="),
            ("is", "=="),
            ("multiplied by", "*"),
            ("divided by", "/"),
            ("plus", "+"),
            ("minus", "-"),
            ("times", "*"),
            ("modulo", "%"),
            ("and", "&&"),
            ("or", "||")
        ]

        for (phrase, op) in infixReplacements {
            text = replaceInfix(text, operatorPhrase: phrase, swiftOp: op)
        }

        // Prefix 'not '
        text = replacePattern(text, pattern: "\\bnot\\s+(\\S+)", replacement: "!$1")

        // Booleans
        text = replaceWord(text, word: "yes", with: "true")
        text = replaceWord(text, word: "no", with: "false")

        return text
    }

    private static func replaceInfix(_ text: String, operatorPhrase: String, swiftOp: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: operatorPhrase)
        let pattern = "(\\S+)\\s+" + escaped + "\\s+(\\S+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }
        var result = text
        while true {
            let range = NSRange(location: 0, length: result.utf16.count)
            guard let match = regex.firstMatch(in: result, options: [], range: range),
                  let r1 = Range(match.range(at: 1), in: result),
                  let r2 = Range(match.range(at: 2), in: result),
                  let fullRange = Range(match.range, in: result) else {
                break
            }
            let left = String(result[r1])
            let right = String(result[r2])
            result.replaceSubrange(fullRange, with: "\(left) \(swiftOp) \(right)")
        }
        return result
    }

    private static func replacePattern(_ text: String, pattern: String, replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }

    private static func replacePrefixPattern(_ text: String, prefix: String, replaceWith: String, suffix: String) -> String {
        var str = text
        while let range = str.range(of: prefix, options: .caseInsensitive) {
            let rest = String(str[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            str = String(str[..<range.lowerBound]) + replaceWith + rest + suffix
            break
        }
        return str
    }

    private static func replaceWord(_ text: String, word: String, with replacement: String) -> String {
        let pattern = "\\b\(word)\\b"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
        }
        return text
    }

    /// Splits a comma-separated list of expressions, respecting string literals
    public static func splitCommaSeparatedExpressions(_ raw: String) -> [String] {
        var items: [String] = []
        var current = ""
        var inString = false
        var quoteChar: Character = "\""
        var parenDepth = 0
        var bracketDepth = 0

        for char in raw {
            if inString {
                current.append(char)
                if char == quoteChar {
                    inString = false
                }
            } else {
                if char == "\"" || char == "'" {
                    inString = true
                    quoteChar = char
                    current.append(char)
                } else if char == "(" {
                    parenDepth += 1
                    current.append(char)
                } else if char == ")" {
                    parenDepth -= 1
                    current.append(char)
                } else if char == "[" {
                    bracketDepth += 1
                    current.append(char)
                } else if char == "]" {
                    bracketDepth -= 1
                    current.append(char)
                } else if char == "," && parenDepth == 0 && bracketDepth == 0 {
                    let trimmed = current.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        items.append(trimmed)
                    }
                    current = ""
                } else {
                    current.append(char)
                }
            }
        }

        let trimmed = current.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            items.append(trimmed)
        }

        return items
    }
}
