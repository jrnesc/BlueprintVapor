/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
//@freestanding(expression)
//public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
//    module: "BlueprintVaporMacros",
//    type: "StringifyMacro"
//)

//@attached(extension)
//@attached(memberAttribute)
//@attached(accessor)
@attached(member, names: arbitrary)
public macro ModelCreation(
    field1: String?,
    field2: String?,
    field3: String?
) = #externalMacro(
    module: "BlueprintVaporMacros",
    type: "ModelCreationMacro"
)
