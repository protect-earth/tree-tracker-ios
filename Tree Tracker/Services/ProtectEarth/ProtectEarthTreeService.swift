import Foundation
import Resolver
import Alamofire

class ProtectEarthTreeService: TreeService {

    @Injected private var database: Database
    @Injected private var sessionFactory: AlamofireSessionFactory
    
    func publish(tree: LocalTree, completion: @escaping (Result<Bool, DataAccessError>) -> Void) {
        fatalError("Not implemented yet!!")
    }
    
    private func getSession() -> Session {
        sessionFactory.get()
    }
    
}
