import Foundation
import UIKit
import Combine
import Resolver

/*
 Controller for sites list
 */
class SitesController: UITableViewController {
    
    @Injected var siteService: SiteService
    
    private var sites: [Site] = []
    private var cancellable: AnyCancellable!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Sites"
        
        self.tableView.register(SimpleTableViewCell.self, forCellReuseIdentifier: "basicStyle")
        
        // nav bar controls
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        navigationItem.rightBarButtonItems?.append(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped)))
        
        // Here we are creating a Combine subscription to a @Published attribute of the SiteService which is handling data access.
        // The closure will be invoked on any change to the data property.
        cancellable = siteService.sitesPublisher.sink() { [weak self] data in
            self?.sites = data.sorted(by: \.name, order: .ascending)
            // reload table view
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - navigation item delegates
    @objc func addTapped() {
        let addSiteController = AddSiteController(siteService: self.siteService)
        if let sheet = addSiteController.sheetPresentationController {
            sheet.detents = [ .medium() ]
        }
        present(addSiteController, animated: true)
    }
    
    @objc func refreshTapped() {
        siteService.sync(completion: {_ in })
    }
    
    // MARK: - Delegate
    override func viewWillAppear(_ animated: Bool) {

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
