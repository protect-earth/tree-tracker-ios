import Foundation

enum ProtectEarthError: Error {
    case remoteError(errorCode: Int, errorMessage: String)
    case localError(errorCode: Int, errorMessage: String)
}
