import SwiftMacros
import AppIntents

// MARK: AppEnumGen Macro
@available(macOS 13.0, *)
@AppEnumGen
enum A: String {
    case a, b
    case c
}

@available(macOS 13.0, *)
// @AppEnumGenFixIt
enum AB: String, AppEnum {
    case a, b
    case c
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "AB"
    
    static var caseDisplayRepresentations: [AB: DisplayRepresentation] = [
        .a: "a", .b: "b",
        .c: "c"
    ]
}
