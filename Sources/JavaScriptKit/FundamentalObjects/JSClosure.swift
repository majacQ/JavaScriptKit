import _CJavaScriptKit

fileprivate var closureRef: JavaScriptHostFuncRef = 0
fileprivate var sharedClosures: [JavaScriptHostFuncRef: ([JSValue]) -> JSValue] = [:]

/// JSClosureProtocol abstracts closure object in JavaScript, whose lifetime is manualy managed
public protocol JSClosureProtocol: JSValueCompatible {

    /// Release this function resource.
    /// After calling `release`, calling this function from JavaScript will fail.
    func release()
}


/// `JSClosure` represents a JavaScript function the body of which is written in Swift.
/// This type can be passed as a callback handler to JavaScript functions.
///
/// e.g.
/// ```swift
/// let eventListenter = JSClosure { _ in
///     ...
///     return JSValue.undefined
/// }
///
/// button.addEventListener!("click", JSValue.function(eventListenter))
/// ...
/// button.removeEventListener!("click", JSValue.function(eventListenter))
/// ```
///
public class JSClosure: JSObject, JSClosureProtocol {
    private var hostFuncRef: JavaScriptHostFuncRef = 0

    @available(*, deprecated, message: "This initializer will be removed in the next minor version update. Please use `init(_ body: @escaping ([JSValue]) -> JSValue)` and add `return .undefined` to the end of your closure")
    @_disfavoredOverload
    public convenience init(_ body: @escaping ([JSValue]) -> ()) {
        self.init({
            body($0)
            return .undefined
        })
    }

    public init(_ body: @escaping ([JSValue]) -> JSValue) {
        self.hostFuncRef = closureRef
        closureRef += 1

        // Retain the given body in static storage by `closureRef`.
        sharedClosures[self.hostFuncRef] = body

        // Create a new JavaScript function which calls the given Swift function.
        var objectRef: JavaScriptObjectRef = 0
        _create_function(self.hostFuncRef, &objectRef)

        super.init(id: objectRef)
    }

    @available(*, deprecated, message: "JSClosure.release() is no longer necessary")
    public func release() {}
}

@_cdecl("_free_host_function_impl")
func _free_host_function_impl(_ hostFuncRef: JavaScriptHostFuncRef) {
    sharedClosures[hostFuncRef] = nil
}


// MARK: - `JSClosure` mechanism note
//
// 1. Create a thunk in the JavaScript world, which has a reference
//    to a Swift closure.
// ┌─────────────────────┬──────────────────────────┐
// │     Swift side      │   JavaScript side        │
// │                     │                          │
// │                     │                          │
// │                     │   ┌──────[Thunk]───────┐ │
// │          ┌ ─ ─ ─ ─ ─│─ ─│─ ─ ─ ─ ─ ┐         │ │
// │          ↓          │   │          │         │ │
// │  [Swift Closure]    │   │  Host Function ID  │ │
// │                     │   │                    │ │
// │                     │   └────────────────────┘ │
// └─────────────────────┴──────────────────────────┘
//
// 2. When the thunk function is invoked, it calls the Swift closure via
//    `_call_host_function` and receives the result through a callback.
// ┌─────────────────────┬──────────────────────────┐
// │     Swift side      │   JavaScript side        │
// │                     │                          │
// │                     │                          │
// │                   Apply ┌──────[Thunk]───────┐ │
// │          ┌ ─ ─ ─ ─ ─│─ ─│─ ─ ─ ─ ─ ┐         │ │
// │          ↓          │   │          │         │ │
// │  [Swift Closure]    │   │  Host Function ID  │ │
// │          │          │   │                    │ │
// │          │          │   └────────────────────┘ │
// │          │          │                    ↑     │
// │          │        Apply                  │     │
// │          └─[Result]─┼───>[Callback func]─┘     │
// │                     │                          │
// └─────────────────────┴──────────────────────────┘

@_cdecl("_call_host_function_impl")
func _call_host_function_impl(
    _ hostFuncRef: JavaScriptHostFuncRef,
    _ argv: UnsafePointer<RawJSValue>, _ argc: Int32,
    _ callbackFuncRef: JavaScriptObjectRef
) {
    guard let hostFunc = sharedClosures[hostFuncRef] else {
        fatalError("The function was already released")
    }
    let arguments = UnsafeBufferPointer(start: argv, count: Int(argc)).map {
        $0.jsValue()
    }
    let result = hostFunc(arguments)
    let callbackFuncRef = JSFunction(id: callbackFuncRef)
    _ = callbackFuncRef(result)
}
