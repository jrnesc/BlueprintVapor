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

public struct ModelCreationMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(
            ClassDeclSyntax.self
        ) else {
            let classError = Diagnostic(
                node: node,
                message: "This is not a class" as! DiagnosticMessage
            )
            context.diagnose(classError)
            return []
        }
        let schema = (declaration as! ClassDeclSyntax).name
        return [
            "static let schema: String = \(schema)",
            "@ID(key: .id) var id: UUID?",
            """
            init(){
            }
            """,
            """
            init(id: UUID? = nil, title: String) { 
                self.id = id
                self.title = title
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
