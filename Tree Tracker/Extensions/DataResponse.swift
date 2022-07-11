import Foundation
import Alamofire

extension DataResponse {
    
    func dataAsUTF8String() -> String {
        guard let data = self.data else { return "" }
        guard let utf8String = String.init( data: data, encoding: .utf8) else { return "" }
        return utf8String
    }
    
}
