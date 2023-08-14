import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(BlueprintVaporMacros)
import BlueprintVaporMacros

let testMacros: [String: Macro.Type] = [
    "ModelCreation": ModelCreationMacro.self
]
#endif

final class BlueprintVaporTests: XCTestCase {
    func testMacro() throws {
        #if canImport(BlueprintVaporMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testModelMacro() throws {
        let expanded = [
            "class Test {",
            "\n\n",
            """
                static let schema: String = "Test"
            """,
            "\n\n",
            "    @ID(key: .id) var id: UUID?",
            "\n\n",
            """
                @Field(key: .string("hello")) var hello: String
                @Field(key: .string("test")) var test: String
                @Field(key: .string("again")) var again: String
            """,
            "\n\n",
            """
                init() {
                }
            """,
            "\n\n",
            """
                init(
                    id: UUID? = nil,
                    hello: String,
                    test: String,
                    again: String
                ) {
                    self.id = id
                    self.hello = hello
                    self.test = test
                    self.again = again
                }
            }
            """,
        ]
        #if canImport(BlueprintVaporMacros)
        assertMacroExpansion(
            """
            @ModelCreation(field1: "hello", field2: "test", field3: "again") class Test {
            }
            """,
            expandedSource: expanded.joined(),
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(BlueprintVaporMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
