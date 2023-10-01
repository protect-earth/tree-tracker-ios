import Foundation
import AWSS3

class AWSS3Configuration {
    
    init(accessKey: String, secretKey: String, region: AWSRegionType = .EUWest1) {
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
        let configuration = AWSServiceConfiguration(region: region, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
}
