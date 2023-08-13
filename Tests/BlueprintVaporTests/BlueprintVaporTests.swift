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
                @Field(key: .string(field1)) var _field1: String

                @Field(key: .string(field2)) var _field2: String

                @Field(key: .string(field3)) var _field3: String
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
                    _field1: String,
                    _field2: String,
                    _field3: String,
                    field1: String,
                    field2: String,
                    field3: String
                ) {
                    self.id = id
                    self._field1 = _field1
                    self._field2 = _field3
                    self._field3 = _field3
                    self.field1 = field1
                    self.field2 = field2
                    self.field3 = field3
                }
            }
            """,
        ]
        #if canImport(BlueprintVaporMacros)
        assertMacroExpansion(
            """
            @ModelCreation(field1: "title", field2: "12345", field3: "qwert") class Test {
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
