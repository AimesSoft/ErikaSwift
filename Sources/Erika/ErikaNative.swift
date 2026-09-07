import CErika
import Foundation

func nativeErrorMessage() -> String {
    guard let pointer = erika_last_error_message() else { return "Erika operation failed." }
    defer { erika_string_free(pointer) }
    return String(cString: pointer)
}

func withOptionalCString<T>(_ value: String?, _ body: (UnsafePointer<CChar>?) throws -> T) throws -> T {
    guard let value else { return try body(nil) }
    guard !value.utf8.contains(0) else {
        throw ErikaError(statusCode: 3, message: "C strings cannot contain a NUL character.")
    }
    return try value.withCString(body)
}

func nativeString(_ pointer: UnsafePointer<CChar>?) -> String? {
    pointer.map { String(cString: $0) }
}

func openNative(_ handle: OpaquePointer, source: String, options: ErikaOpenOptions) throws {
    let pairs = options.httpHeaders.sorted { $0.key < $1.key }
    let strings = pairs.flatMap { [$0.key, $0.value] }
    guard !strings.contains(where: { $0.utf8.contains(0) }) else {
        throw ErikaError(statusCode: 3, message: "HTTP headers cannot contain NUL characters.")
    }
    var allocated: [UnsafeMutablePointer<CChar>] = []
    defer { allocated.forEach { free($0) } }
    for string in strings {
        guard let pointer = strdup(string) else {
            throw ErikaError(statusCode: 3, message: "Could not allocate HTTP header storage.")
        }
        allocated.append(pointer)
    }
    let headers = pairs.indices.map {
        CErika.ErikaHttpHeader(name: UnsafePointer(allocated[$0 * 2]), value: UnsafePointer(allocated[$0 * 2 + 1]))
    }
    try withOptionalCString(source) { uri in
        try headers.withUnsafeBufferPointer { buffer in
            var native = CErika.ErikaOpenOptions(
                headers: buffer.baseAddress, header_count: UInt(buffer.count),
                http_read_ahead_bytes: options.httpReadAheadBytes, reserved: (0, 0, 0)
            )
            try erikaCheck(erika_presenter_open_with_options(handle, uri, &native))
        }
    }
}

func signedMicroseconds(_ seconds: TimeInterval) throws -> Int64 {
    let value = seconds * 1_000_000
    guard value.isFinite, value >= Double(Int64.min), value < Double(Int64.max) else {
        throw ErikaError(statusCode: 3, message: "Time is outside the signed microsecond range.")
    }
    return Int64(value)
}

func positionMicroseconds(_ seconds: TimeInterval) throws -> UInt64 {
    let value = seconds * 1_000_000
    guard value.isFinite, value >= 0, value < Double(UInt64.max) else {
        throw ErikaError(statusCode: 3, message: "Position must be finite, non-negative and fit UInt64 microseconds.")
    }
    return UInt64(value)
}
