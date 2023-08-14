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

/// @ModelCreation final class Test {}
///
/// expands to:
///
/// final class Test {
/// static let schema: String = "Tests"
/// @ID(key: .id) var id: UUID?
/// @Field(key: title) var title: String
///
/// init() {}
///
/// init(id: UUID? = nil, title: String) {
///    self.id = id
///    self.title = title
///   }
///}

// Another expansion that creates controllers. Controller will define Model based on controller name.
// Also declare an enum...
// Is it possible to iterate across the enum and create `fields` dependent on the number of members (cases)?

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

        let schema = declaration.asProtocol(NamedDeclSyntax.self)!
            .name
            .trimmedDescription

        var fields: [String] = []

        var numbOfFields: Int

        if let args = node.arguments {
            if let labeledExprList = args.as(LabeledExprListSyntax.self) {
                for labeledExpr in labeledExprList {
                    if let arrayExprElements = labeledExpr.expression
                        .as(ArrayExprSyntax.self)?
                        .elements {
                        for segments in arrayExprElements {
                            if let segment = segments.expression.as(StringLiteralExprSyntax.self)?.segments {
                                for content in segment {
                                    fields.append("\(content)".trimmingCharacters(in: .whitespacesAndNewlines))
                                }
                            }
                        }
                    }
                }
            }
        }

        var codeBlock: [DeclSyntax] = [
            """
            static let schema: String = "\(raw: schema)"
            """,
            "@ID(key: .id) var id: UUID?",
            """
            init() { }
            """
        ]
        
        var insertFields: [DeclSyntax] {
            var decl: [DeclSyntax] = []

            for (_, value) in fields.enumerated() {
                decl.append(
                """
                @Field(key: .string("\(raw: value)")) var \(raw: value): String
                """
                )
            }

            return decl
        }
        
        var insertInitFields: [DeclSyntax] {
            var decl: [DeclSyntax] = [
                """
                init(
                """
            ]

            for (_, value) in fields.enumerated() {
                decl.append(
                """
                    \(raw: value): String,
                """
                )
            }
            
            decl.append(
                """
                    id: id: UUID? = nil
                ) {
                """
            )
            
            for (_, value) in fields.enumerated() {
                decl.append(
                """
                    self.\(raw: value.replacingOccurrences(of: "\n\n", with: "")) = \(raw: value)
                """
                )
            }
            
            decl.append(
                """
                    self.id = id
                }
                """
            )

            return decl
        }
        
        codeBlock.insert(contentsOf: insertFields + insertInitFields, at: 2)

        return codeBlock
    }
}

@main
struct BlueprintVaporPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
//        StringifyMacro.self,
        ModelCreationMacro.self
    ]
}
