import Foundation

enum Constants {
    enum Http {
        static let requestWaitsForConnectivity = true
        static let requestTimeoutSeconds: TimeInterval = 30
        static let requestRetryDelaySeconds = 2
        static let requestRetryLimit = 3
        static let protectEarthApiVersion: String? = nil
        static let protectEarthApiBaseUrl = Secrets.protectEarthApiBaseUrl
        static let protectEarthEnvironmentName = Secrets.protectEarthEnvName
    }
}
