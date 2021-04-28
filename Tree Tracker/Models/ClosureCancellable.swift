struct ClosureCancellable: Cancellable {
    private let handler: () -> Void
    
    init(handler: @escaping () -> Void) {
        self.handler = handler
    }
    
    func cancel() {
        handler()
    }
}
