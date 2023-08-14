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

        var new: [String] = []
        var labels: [String] = []
        if let args = node.arguments {
            if let labeledExprList = args.as(LabeledExprListSyntax.self) {
                for labeledExpr in labeledExprList {
                    if let segmentList = labeledExpr
                        .expression
                        .as(StringLiteralExprSyntax.self)?
                        .segments,
                       let argLabel = labeledExpr
                        .label?
                        .as(TokenSyntax.self)?
                        .text {
                        labels.append("\(argLabel)")
                        for segment in segmentList {
                            if let content = segment.as(StringSegmentSyntax.self)?.content {
                                new.append("\(content)".trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                        }
                    }
                }
            }
        }

//        let codeBlock: [String] = []

        return [
            """
            static let schema: String = "\(raw: schema)"
            """,
            "@ID(key: .id) var id: UUID?",
            """
            @Field(key: .string("\(raw: new[0])")) var \(raw: labels[0]): String
            @Field(key: .string("\(raw: new[1])")) var \(raw: labels[1]): String
            @Field(key: .string("\(raw: new[2])")) var \(raw: labels[2]): String
            """,
            """
            init() {
            }
            """,
            """
            init(
                id: UUID? = nil,
                \(raw: labels[0]): String,
                \(raw: labels[1]): String,
                \(raw: labels[2]): String
            ) {
                self.id = id
                self.\(raw: labels[0]) = \(raw: labels[0])
                self.\(raw: labels[1]) = \(raw: labels[1])
                self.\(raw: labels[2]) = \(raw: labels[2])
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
