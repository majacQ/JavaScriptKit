public class JSRef: Equatable {
    let id: UInt32
    fileprivate init(id: UInt32) {
        self.id = id
    }
    public static func global() -> JSRef {
        .init(id: _JS_Predef_Value_Global)
    }

    deinit {

    }

    public static func == (lhs: JSRef, rhs: JSRef) -> Bool {
        return lhs.id == rhs.id
    }
}

public enum JSValue: Equatable {
    case boolean(Bool)
    case string(String)
}

protocol JSValueConvertible {
    func jsValue() -> JSValue
}

extension Bool: JSValueConvertible {
    func jsValue() -> JSValue {
        .boolean(self)
    }
}

import _CJavaScriptKit

public func getJSValue(this: JSRef, name: String) -> JSValue {
    var kind: JavaScriptValueKind = JavaScriptValueKind_Invalid
    var payload1: JavaScriptPayload = 0
    var payload2: JavaScriptPayload = 0
    _get_js_value(this.id, name, Int32(name.count), &kind, &payload1, &payload2)
    switch kind {
    case JavaScriptValueKind_Invalid:
        fatalError()
    case JavaScriptValueKind_Boolean:
        return .boolean(payload1 != 0)
    case JavaScriptValueKind_String:
        let buffer = malloc(Int(payload2))!.assumingMemoryBound(to: UInt8.self)
        _load_string(payload1 as JavaScriptValueId, buffer)
        let string = String(decodingCString: UnsafePointer(buffer), as: UTF8.self)
        return .string(string)
    default:
        fatalError("unreachable")
    }
}

public func setJSValue(this: JSRef, name: String, value: JSValue) {

    let kind: JavaScriptValueKind
    let payload: JavaScriptPayload
    switch value {
    case let .boolean(boolValue):
        kind = JavaScriptValueKind_Boolean
        payload = boolValue ? 1 : 0
    case var .string(stringValue):
        kind = JavaScriptValueKind_String
        stringValue.withUTF8 { bufferPtr in
            let ptrValue = UInt32(UInt(bitPattern: bufferPtr.baseAddress!))
            _set_js_value(this.id, name, Int32(name.count), kind, ptrValue, 0)
        }
        return
    }
    _set_js_value(this.id, name, Int32(name.count), kind, payload, 0)
}


#if Xcode
func _set_js_value(
    _ _this: JavaScriptValueId,
    _ prop: UnsafePointer<Int8>!, _ length: Int32,
    _ kind: JavaScriptValueKind,
    _ payload1: JavaScriptPayload,
    _ payload2: JavaScriptPayload) { fatalError() }
func _get_js_value(
    _ _this: JavaScriptValueId,
    _ prop: UnsafePointer<Int8>!, _ length: Int32,
    _ kind: UnsafeMutablePointer<JavaScriptValueKind>!,
    _ payload1: UnsafeMutablePointer<JavaScriptPayload>!,
    _ payload2: UnsafeMutablePointer<JavaScriptPayload>!) { fatalError() }
func _load_string(_ ref: JavaScriptValueId, _ buffer: UnsafeMutablePointer<UInt8>!) { fatalError() }
#endif