import Foundation

// MARK: - Source Location
public struct SourceLocation: Equatable, Sendable {
    public let line: Int
    public let column: Int

    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
}

// MARK: - Mutation Operator
public enum MutationOp: String, Equatable, Sendable {
    case increase = "+="
    case decrease = "-="
    case multiply = "*="
    case divide = "/="
}

// MARK: - Input Type
public enum InputType: Equatable, Sendable {
    case string
    case number
    case integer
}

// MARK: - Binary Operator
public enum BinaryOp: String, Equatable, Sendable {
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"
    case equal = "=="
    case notEqual = "!="
    case greaterThan = ">"
    case lessThan = "<"
    case greaterThanOrEqual = ">="
    case lessThanOrEqual = "<="
    case and = "&&"
    case or = "||"
    case contains = "contains"
    case startsWith = "startsWith"
    case endsWith = "endsWith"
}

// MARK: - Unary Operator
public enum UnaryOp: String, Equatable, Sendable {
    case not = "!"
    case minus = "-"
}

// MARK: - Function Parameter
public struct FunctionParameter: Equatable, Sendable {
    public let name: String
    public let typeName: String

    public init(name: String, typeName: String = "Any") {
        self.name = name
        self.typeName = typeName
    }
}

// MARK: - Key-Value Pair for Dictionaries
public struct KeyValuePair: Equatable, Sendable {
    public let key: Expression
    public let value: Expression

    public init(key: Expression, value: Expression) {
        self.key = key
        self.value = value
    }
}

// MARK: - Else If Clause
public struct ElseIfClause: Equatable, Sendable {
    public let condition: Expression
    public let body: [Statement]

    public init(condition: Expression, body: [Statement]) {
        self.condition = condition
        self.body = body
    }
}

// MARK: - Expression AST
public indirect enum Expression: Equatable, Sendable {
    case literalString(String)
    case literalInt(Int)
    case literalDouble(Double)
    case literalBool(Bool)
    case literalList([Expression])
    case literalDict([KeyValuePair])
    case variable(String)
    case binary(Expression, BinaryOp, Expression)
    case unary(UnaryOp, Expression)
    case call(name: String, arguments: [Expression])
    case indexAccess(base: Expression, index: Expression)
    case firstItem(Expression)
    case lastItem(Expression)
    case countOf(Expression)
    case uppercaseOf(Expression)
    case lowercaseOf(Expression)
    case mathFunc(name: String, argument: Expression)
    case rawSwift(String)
}

// MARK: - Statement AST
public enum Statement: Equatable, Sendable {
    case say([Expression])
    case setVariable(name: String, value: Expression, isConstant: Bool)
    case changeVariable(name: String, value: Expression)
    case mutateVariable(name: String, op: MutationOp, value: Expression)
    case askUser(target: String, prompt: Expression, type: InputType)
    case ifCondition(
        condition: Expression,
        thenBranch: [Statement],
        elseIfs: [ElseIfClause],
        elseBranch: [Statement]?
    )
    case repeatCount(times: Expression, body: [Statement])
    case repeatRange(variable: String, from: Expression, to: Expression, body: [Statement])
    case repeatInfinite(body: [Statement])
    case forEach(variable: String, collection: Expression, body: [Statement])
    case whileLoop(condition: Expression, body: [Statement])
    case breakLoop
    case continueLoop
    case returnStatement(Expression?)
    case functionDefinition(name: String, parameters: [FunctionParameter], returnType: String?, body: [Statement])
    case functionCall(name: String, arguments: [Expression])
    case listAdd(item: Expression, list: String)
    case listRemove(item: Expression, list: String)
    case listRemoveAt(index: Expression, list: String)
    case listClear(list: String)
    case listSort(list: String)
    case listReverse(list: String)
    case wait(seconds: Expression)
    case getRandom(from: Expression, to: Expression, target: String, isDouble: Bool)
    case getDate(target: String)
    case getTime(target: String)
    case writeFile(content: Expression, path: Expression)
    case appendFile(content: Expression, path: Expression)
    case readFile(path: Expression, target: String)
    case checkFileExists(path: Expression, target: String)
    case deleteFile(path: Expression)
    case fetchURL(url: Expression, target: String)
    case shellCommand(command: Expression, target: String)
    case exitProgram
    case rawSwift(String)
    case expressionStatement(Expression)
}

// MARK: - Program AST
public struct Program: Equatable, Sendable {
    public let statements: [Statement]

    public init(statements: [Statement]) {
        self.statements = statements
    }
}

// MARK: - Sweasy Error
public struct SweasyError: LocalizedError, Equatable, Sendable {
    public let message: String
    public let line: Int?
    public let column: Int?

    public init(_ message: String, line: Int? = nil, column: Int? = nil) {
        self.message = message
        self.line = line
        self.column = column
    }

    public var errorDescription: String? {
        if let line = line {
            if let col = column {
                return "Sweasy Error at line \(line), column \(col): \(message)"
            }
            return "Sweasy Error at line \(line): \(message)"
        }
        return "Sweasy Error: \(message)"
    }
}
