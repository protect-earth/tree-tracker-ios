import Foundation
import UIKit
import Combine

/*
 Controller for sites list
 */
class SitesController: UITableViewController {
    
    private let database = CurrentEnvironment.database
    private var entitiesModel: EntitiesViewModel = EntitiesViewModel()
    
    private var sites: [Site] = []
    private var cancellable: AnyCancellable!

    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.title = "Sites"
        
        self.tableView.register(SimpleTableViewCell.self, forCellReuseIdentifier: "basicStyle")
        
        // nav bar controls
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        navigationItem.rightBarButtonItems?.append(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped)))
        
        // here we are creating a Combine subscription to a @Published attribute of the entity view model which is handling data access
        // the closure will be invoked on any change to the data property, which is itself refreshed via the onAppear method called
        // in this controllers viewWillAppear() handler
        cancellable = entitiesModel.$data.sink() { [weak self] data in
            // refresh local sites array from database
            self?.database.fetchAll(Site.self, completion: { [weak self] sites in
                self?.sites = sites.sorted(by: \.name, order: .ascending)
                // reload table view
                self?.tableView.reloadData()
            })
            
        }
    }
    
    // MARK: - navigation item delegates
    @objc func addTapped() {
        let addSiteController = AddSiteController(entitiesViewModel: entitiesModel)
        if let sheet = addSiteController.sheetPresentationController {
            sheet.detents = [ .medium() ]
        }
        present(addSiteController, animated: true)
    }
    
    @objc func refreshTapped() {
        entitiesModel.sync()
    }
    
    // MARK: - Delegate
    
    override func viewWillAppear(_ animated: Bool) {
        entitiesModel.onAppear()
    }
    
    // MARK: - Datasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sites.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        
        cell.textLabel?.text = sites[indexPath.item].name
        cell.isUserInteractionEnabled = false

        return cell
    }
    
}
