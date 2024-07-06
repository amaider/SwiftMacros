import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SwiftMacrosMacros)
import SwiftMacrosMacros

let testMacros: [String: Macro.Type] = [
    "AppEnumGen": AppEnumGenMacro.self,
    "AppEnumGenFixIt": AppEnumGenFixItMacro.self,
]
#endif

final class SwiftMacrosTests: XCTestCase {
    // MARK: For debugging with breakpoints
    func testSyntaxDebugging() throws {
#if canImport(SwiftMacrosMacros)
        assertMacroExpansion(
            """
            @AppEnumGenFixIt
            enum A: String, AppEnu {
                case a, b
                case c
            
                static var typeDisplayRepresentation: TypeDisplayRepresentation = "A"
            
                static var caseDisplayRepresentations: [A: DisplayRepresentation] = [
                    .a: "a", .b: "b",
                    .c: "c"
                ]
            }
            """,
            expandedSource: "", macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    // MARK: Test successful but useless because of errors in compiling when using it in actual project -> FixIt solution
    func testAppEnumGen() throws {
#if canImport(SwiftMacrosMacros)
        assertMacroExpansion(
            """
            @AppEnumGen
            enum A: String, AppEnum {
                case a, b
                case c
            }
            """,
            expandedSource:
            """
            
            enum A: String, AppEnum {
                case a, b
                case c
            }
            
            extension A: AppEnum {
                static var typeDisplayRepresentation: TypeDisplayRepresentation = "A"
            
                static var caseDisplayRepresentations: [A: DisplayRepresentation] = [
                    .a: "a", .b: "b",
                .c: "c"
                ]
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    // MARK: Original idea
    func testIntentedMacro() throws {
#if canImport(SwiftMacrosMacros)
        assertMacroExpansion(
            """
            @AppEnumGen
            enum A: String {
                case a, b
                case c
            }
            """,
            expandedSource:
            """
            
            enum A: String {
                case a, b
                case c
            }
            
            extension A: AppEnum {
                static var typeDisplayRepresentation: TypeDisplayRepresentation = "A"
            
                static var caseDisplayRepresentations: [A: DisplayRepresentation] = [
                    .a: "a", .b: "b",
                .c: "c"
                ]
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
