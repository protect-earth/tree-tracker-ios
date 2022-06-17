import Foundation
import UIKit
import Combine
import Resolver

/*
 Controller for species list
 */
class SpeciesController: UITableViewController {
    
    @Injected var speciesService: SpeciesService
    
    private var species: [Species] = []
    private var cancellable: AnyCancellable!

    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.title = "Species"
        
        self.tableView.register(SimpleTableViewCell.self, forCellReuseIdentifier: "basicStyle")
        
        // nav bar controls
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped))
        
        cancellable = speciesService.speciesPublisher.sink() { [weak self] data in
            self?.species = data.sorted(by: \.name, order: .ascending)
            // reload table view
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - navigation item delegates
    @objc func refreshTapped() {
        speciesService.sync() {_ in}
    }
    
    // MARK: - Delegate
    override func viewWillAppear(_ animated: Bool) {

    }
    
    // MARK: - Datasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return species.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        
        cell.textLabel?.text = species[indexPath.item].name
        cell.isUserInteractionEnabled = false

        return cell
    }
    
}
