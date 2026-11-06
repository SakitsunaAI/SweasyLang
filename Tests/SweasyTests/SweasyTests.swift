import Testing
@testable import SweasyCore

@Suite("Sweasy Tests")
struct SweasyTests {
    @Test("Test variable transpilation")
    func testVariable() throws {
        let parser = Parser()
        let program = try parser.parse(source: "Set score to 100")
        let transpiler = Transpiler()
        let swiftCode = transpiler.transpile(program)
        #expect(swiftCode.contains("var score = 100"))
    }

    @Test("Test math and operator transformation")
    func testMath() throws {
        let parser = Parser()
        let program = try parser.parse(source: "Set sum to a plus b")
        let transpiler = Transpiler()
        let swiftCode = transpiler.transpile(program)
        #expect(swiftCode.contains("var sum = a + b"))
    }

    @Test("Test output statement")
    func testSay() throws {
        let parser = Parser()
        let program = try parser.parse(source: "Say \"Hello World\"")
        let transpiler = Transpiler()
        let swiftCode = transpiler.transpile(program)
        #expect(swiftCode.contains("_sweasy_print(\"Hello World\")"))
    }
}
