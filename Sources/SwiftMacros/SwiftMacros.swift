import AppIntents

// MARK: AppEnumGen Macro
/// A macro that conforms an enum to an AppEnum
///
///     enum A: String {
///         case a, b
///         case c
///     }
///
/// extends the enum with
///
///     extension A: AppEnum {
///         static var typeDisplayRepresentation: TypeDisplayRepresentation = "A"
///
///         static var caseDisplayRepresentations: [A: DisplayRepresentation] = [
///             .a: "a", .b: "b",
///             .c: "c"
///         ]
///     }
///
/// Use the FixIt version for now.
///
//  Compiler error in an actual project:    Unable to find matching source file for path "@__swiftmacro_13Complications3ABC5AppEnumGenfMe_.swift
//  Warning error on extension:            Conformance to 'Sendable' must occur in the same source file as enum 'A'; use '@unchecked Sendable' for retroactive conformance
@attached(extension, conformances: AppEnum, names: named(typeDisplayRepresentation), named(caseDisplayRepresentations))
public macro AppEnumGen() = #externalMacro(module: "SwiftMacrosMacros", type: "AppEnumGenMacro")

// (ab)uses the FixIt to replace the enum. Can also be used to update it after changes (uncomment and press Fix in warning)
@attached(extension, conformances: AppEnum, names: named(typeDisplayRepresentation), named(caseDisplayRepresentations))
public macro AppEnumGenFixIt() = #externalMacro(module: "SwiftMacrosMacros", type: "AppEnumGenFixItMacro")
