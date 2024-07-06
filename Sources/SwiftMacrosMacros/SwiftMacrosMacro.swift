import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: AppEnumGen Macro
// TODO: Use actual Swift Syntax instead of just SyntaxProtocol, if you gain something (shorter compile time?) from it
public enum AppEnumGenMacro: ExtensionMacro {
public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    /// cast declaration to enumDeclaration
    guard let enumDecl: EnumDeclSyntax = declaration.as(EnumDeclSyntax.self) else {
        context.diagnose( Diagnostic(node: node, message: SwiftMacros_Diagnostic.notAnEnum) )
        return []
    }
    
    /// get enum name
    let enumName: TokenSyntax = enumDecl.name.trimmed
    
    /// typeDisplayRepresentationSyntax
    let typeDisplayRepresentationSyntax: VariableDeclSyntax = try VariableDeclSyntax(
            """
            static var typeDisplayRepresentation: TypeDisplayRepresentation = "\(enumName)"
            """
    )
    
    /// get cases: caseDecls are each line of the cases
    let members: MemberBlockItemListSyntax = enumDecl.memberBlock.members
    let caseDecls: [EnumCaseDeclSyntax] = members.compactMap({ $0.decl.as(EnumCaseDeclSyntax.self) })
    // let allCases: [EnumCaseElementSyntax] = caseDecls.flatMap({ $0.elements })
    
    /// mulitple lines, respectivly to original case declaractions
    let dictLines: String = caseDecls.compactMap({ caseDecl in
        caseDecl.elements.compactMap({ element in
                """
                .\(element.name): "\(element.name)"
                """
        }).joined(separator: ", ")
    }).joined(separator: ",\n")
    
    let caseDisplayRepresentationsSyntax: VariableDeclSyntax = try VariableDeclSyntax(
            """
            static var caseDisplayRepresentations: [\(enumName): DisplayRepresentation] = [
                \(raw: dictLines)
            ]
            """
    )
    
    let extensionDecl: ExtensionDeclSyntax = try ExtensionDeclSyntax(
            """
            extension \(enumName): AppEnum {
                \(typeDisplayRepresentationSyntax)
            
                \(caseDisplayRepresentationsSyntax)
            }
            """
    )
    
    return [extensionDecl]
}
}

// MARK: AppEnumGenFixIt Macro
public enum AppEnumGenFixItMacro: ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        /// cast declaration to enumDeclaration
        guard let enumDecl: EnumDeclSyntax = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose( Diagnostic(node: node, message: SwiftMacros_Diagnostic.notAnEnum) )
            return []
        }
        
        /// get enum name
        let enumName: TokenSyntax = enumDecl.name.trimmed
        
        /// typeDisplayRepresentationSyntax
        var typeDisplayRepresentationSyntax: VariableDeclSyntax = try VariableDeclSyntax(
            """
            static var typeDisplayRepresentation: TypeDisplayRepresentation = "\(enumName)"
            """
        )
        
        /// get cases: caseDecls are each line of the cases
        let members: MemberBlockItemListSyntax = enumDecl.memberBlock.members
        let caseDecls: [EnumCaseDeclSyntax] = members.compactMap({ $0.decl.as(EnumCaseDeclSyntax.self) })
        // let allCases: [EnumCaseElementSyntax] = caseDecls.flatMap({ $0.elements })
        
        /// mulitple lines, respectivly to original case declaractions
        let dictLines: String = caseDecls.compactMap({ caseDecl in
            caseDecl.elements.compactMap({ element in
                """
                .\(element.name): "\(element.name)"
                """
            }).joined(separator: ", ")
        }).joined(separator: ",\n")
        
        var caseDisplayRepresentationsSyntax: VariableDeclSyntax = try VariableDeclSyntax(
            """
            static var caseDisplayRepresentations: [\(enumName): DisplayRepresentation] = [
                \(raw: dictLines)
            ]
            """
        )
        
        /// FixIt Syntax
        var fixItSyntax = enumDecl
        
        /// replace '@AppEnumGen' with '//@AppEnumGen'
        if var commentedMacro = fixItSyntax.attributes.first?.as(AttributeSyntax.self) {
            commentedMacro.atSign = TokenSyntax("//@")
            
            fixItSyntax.attributes = AttributeListSyntax(itemsBuilder: {
                commentedMacro
            })
        }
        
        /// check if AppEnum inheritance already exists
        if fixItSyntax.inheritanceClause?.inheritedTypes != nil, !fixItSyntax.inheritanceClause!.inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.name.text == "AppEnum" }) {
            /// get all inheritances and modify if needed
            var updatedInheritances = fixItSyntax.inheritanceClause?.inheritedTypes.enumerated().map({ (index, inheritance) in
                /// skip if it has comma
                guard inheritance.as(InheritedTypeSyntax.self)?.trailingComma?.text != "," else { return inheritance }
                // FIXME: guard inheritance.as(InheritedTypeSyntax.self)?.trailingComma != .commaToken(trailingTrivia: .spaces(1)) else { return inheritance }
                
                /// remove space and add comma
                guard let inheritanceName = inheritance.type.as(IdentifierTypeSyntax.self)?.name.text else { return inheritance }
                let updatedInheritance = InheritedTypeSyntax(type: IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: inheritanceName)), trailingComma: .commaToken())
                
                return updatedInheritance
            })
            
            /// add AppEnum inheritance
            let appEnumInheritance: InheritedTypeSyntax = InheritedTypeSyntax(leadingTrivia: .space, type: TypeSyntax("AppEnum"), trailingTrivia: .space)
            updatedInheritances?.append(appEnumInheritance)
            
            /// set new inheritances
            guard let updatedInheritances else {
                context.diagnose( Diagnostic(node: node, message: SwiftMacros_Diagnostic.updatedInheritancesIsNil) )
                return []
            }
            fixItSyntax.inheritanceClause?.inheritedTypes = InheritedTypeListSyntax(updatedInheritances)
        }
        
        /// conform to AppEnum by adding the static variables
        typeDisplayRepresentationSyntax.leadingTrivia = .newlines(2)
        caseDisplayRepresentationsSyntax.leadingTrivia = .newlines(2)
        
        /// keep 'case' members
        fixItSyntax.memberBlock.members = fixItSyntax.memberBlock.members.filter({ $0.decl.is(EnumCaseDeclSyntax.self) })
        /// add variables
        fixItSyntax.memberBlock.members.append(MemberBlockItemSyntax(decl: DeclSyntax(typeDisplayRepresentationSyntax)))
        fixItSyntax.memberBlock.members.append(MemberBlockItemSyntax(decl: DeclSyntax(caseDisplayRepresentationsSyntax)))
        
        /// show fixIt
        let fixItChange: FixIt.Change = .replace(oldNode: declaration._syntaxNode, newNode: fixItSyntax._syntaxNode)
        let message: FixItMessage = SwiftMacros_FixItMessage(message: "Update AppEnum", fixItID: .init(domain: "AmaiderMacroFixIt", id: "replaceEnum"))
        let replaceDiagnostic: Diagnostic = Diagnostic(node: node, message: SwiftMacros_Diagnostic.replaceEnum, fixIt: FixIt(message: message, changes: [fixItChange]))
        context.diagnose(replaceDiagnostic)
        
        /// return empty extensionMacro so it doesnt generate errors on 'update' and extension macro is useless anyway
        return []
    }
}

@main
struct SwiftMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AppEnumGenMacro.self,
        AppEnumGenFixItMacro.self,
    ]
}

// MARK: Diagnostic Errors/Warnings
enum SwiftMacros_Diagnostic: String, DiagnosticMessage {
    case notAnEnum
    case updatedInheritancesIsNil
    
    case replaceEnum
    
    var severity: DiagnosticSeverity {
        switch self {
            case .notAnEnum, .updatedInheritancesIsNil:
                    .error
            case .replaceEnum:
                    .warning
        }
    }
    
    var message: String {
        switch self {
            case .notAnEnum: "'@AppEnumGen' can only be applied to an 'enum'"
            case .updatedInheritancesIsNil: "Somehow updatedInheritances is nil"
            case .replaceEnum: "Replace the enum with the macro expansion"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "de.amaider.SwiftMacros", id: rawValue)
    }
}

struct SwiftMacros_FixItMessage: FixItMessage {
    var message: String
    var fixItID: SwiftDiagnostics.MessageID
}
