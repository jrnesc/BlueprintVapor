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
@attached(member, names: named(id), named(title), named(init()), named(init(id:)), named(init(title:)))
public macro ModelCreation() = #externalMacro(
    module: "BlueprintVaporMacros",
    type: "BlueprintVaporMacro"
)
