import CErika
import Foundation

public struct ErikaError: Error, LocalizedError, Sendable, Equatable {
    public let statusCode: Int32
    public let message: String

    public init(statusCode: Int32, message: String) {
        self.statusCode = statusCode
        self.message = message
    }

    public var errorDescription: String? { message }
}

@inline(__always)
func erikaCheck(_ status: ErikaStatus) throws {
    guard status == ErikaStatus_Ok else {
        var message = "Erika operation failed with status \(status.rawValue)."
        if let pointer = erika_last_error_message() {
            message = String(cString: pointer)
            erika_string_free(pointer)
        }
        throw ErikaError(statusCode: Int32(status.rawValue), message: message)
    }
}
