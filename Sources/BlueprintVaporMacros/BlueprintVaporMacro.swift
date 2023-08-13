import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

// @ModelCreation final class Test {}
//
// expands to:
//
// final class Test {
// static let schema: String = "Tests"
// @ID(key: .id) var id: UUID?
// @Field(key: title) var title: String

// init() {}

// init(id: UUID? = nil, title: String) {
//    self.id = id
//    self.title = title
//   }
//}

public struct ModelCreationMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(
            ClassDeclSyntax.self
        )
        else {
            let classError = Diagnostic(
                node: node,
                message: "This is not a class" as! DiagnosticMessage
            )
            context.diagnose(classError)
            return []
        }
        let schema = declaration.asProtocol(NamedDeclSyntax.self)!.name.trimmedDescription
//        let names = node.asProtocol(MemberTypeSyntax.self)!.argumentList.first

        return [
            """
            static let schema: String = "\(raw: String(describing: schema))"
            """,
            "@ID(key: .id) var id: UUID?",
            "@Field(key: .string(field1)) var _field1: String?",
            "@Field(key: .string(field2)) var _field2: String?",
            "@Field(key: .string(field3)) var _field3: String?",
            """
            init() {
            }
            """,
            """
            init(
                id: UUID? = nil,
                _field1: String? = nil,
                _field2: String? = nil,
                _field3: String? = nil
            ) {
                self.id = id
                self._field1 = _field1
                self._field2 = _field3
                self._field3 = _field3
            }
            """,
        ]
    }
}

@main
struct BlueprintVaporPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
//        StringifyMacro.self,
        ModelCreationMacro.self
    ]
}
