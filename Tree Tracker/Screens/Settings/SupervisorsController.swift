import Foundation
import UIKit
import Combine
import Resolver

/*
 Controller for supervisors list
 */
class SupervisorsController: UITableViewController {
    
    @Injected var supervisorService: SupervisorService
    
    private var supervisors: [Supervisor] = []
    private var cancellable: AnyCancellable!

    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.title = "Supervisors"
        
        self.tableView.register(SimpleTableViewCell.self, forCellReuseIdentifier: "basicStyle")
        
        // nav bar controls
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped))
        
        // here we are creating a Combine subscription to a @Published attribute of the entity view model which is handling data access
        // the closure will be invoked on any change to the data property, which is itself refreshed via the onAppear method called
        // in this controllers viewWillAppear() handler
        cancellable = supervisorService.supervisorPublisher.sink() { [weak self] data in
            self?.supervisors = data.sorted(by: \.name, order: .ascending)
            // reload table view
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - navigation item delegates
    @objc func refreshTapped() {
        supervisorService.sync() {_ in}
    }
    
    // MARK: - Delegate
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    // MARK: - Datasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return supervisors.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        
        cell.textLabel?.text = supervisors[indexPath.item].name
        cell.isUserInteractionEnabled = false

        return cell
    }
    
}
