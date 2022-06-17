import Foundation

enum DataAccessError: Error {
    case remoteError(errorCode: Int, errorMessage: String)
}
