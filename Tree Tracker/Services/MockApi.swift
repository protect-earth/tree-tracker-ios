import Foundation
import Alamofire
import class UIKit.UIImage

fileprivate extension UIImage {
    static var mockTree1: UIImage { UIImage(named: "mockTree1")! }
    static var mockTree2: UIImage { UIImage(named: "mockTree2")! }
    static var mockTree3: UIImage { UIImage(named: "mockTree3")! }
}

final class MockApi: Api {
    let errorRate = 5 // percentage of error responses
    let delayRange = 0.0...0.3 // the delay of a response will be randomly selected from this range
    
    private(set) var treesPlanted = [AirtableTree]()
    private(set) var species: [AirtableSpecies] = [.init(id: "1", name: "Alder"), .init(id: "2", name: "Bird Cherry"), .init(id: "3", name: "Elder")]
    private(set) var sites: [AirtableSite] = [.init(id: "1", name: "Howard Court"), .init(id: "2", name: "Donkeywell Farm")]
    private(set) var supervisors: [AirtableSupervisor] = [.init(id: "1", name: "Josh Hopkins")]
    private var images = [UIImage.mockTree1, .mockTree2, .mockTree3]
    
    func upload(tree: LocalTree, progress: @escaping (Double) -> Void, completion: @escaping (Result<AirtableTree, AFError>) -> Void) -> Cancellable {
        var isCancelled = false
        
        let maxEntries = 5
        var currentEntry = 0
        delayUntil {
            if isCancelled {
                return false
            }
            
            progress(Double(currentEntry) * 0.2)
            let finishedUpload = currentEntry >= (maxEntries - 1)
            
            if finishedUpload {
                let id = Int(Date.now.timeIntervalSince1970 * 100) - 161962124000
                completion(.success(tree.toAirtableTree(id: id, imageUrl: "https://google.com/\(id)")))
            } else {
                currentEntry += 1
            }
            return !finishedUpload
        }
        
        return ClosureCancellable {
            isCancelled = true
            completion(.failure(.explicitlyCancelled))
        }
    }
    
    func loadImage(url: String, completion: @escaping (UIImage?) -> Void) {
        delay {
            completion(self.images.randomElement())
        }
    }
    
    private func delay(completion: @escaping () -> Void) {
        let delay = TimeInterval.random(in: delayRange)
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            completion()
        }
    }
    
    private func delayUntil(completion: @escaping () -> Bool) {
        delay { [weak self] in
            let shouldContinue = completion()
            
            if shouldContinue {
                self?.delayUntil(completion: completion)
            }
        }
    }
    
    private func delayAndCompleteWithPossibleError<T>(successResponse: T, completionToCall: @escaping (Result<T, AFError>) -> Void) {
        let delay = TimeInterval.random(in: delayRange)
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            let shouldResponseBeSuccessful = Int.random(in: 0...100) > self.errorRate
            let response: Result<T, AFError> = shouldResponseBeSuccessful ? .success(successResponse) : .failure(AFError.explicitlyCancelled)
            completionToCall(response)
        }
    }
}
