import Foundation
import UIKit
import Combine

/*
 Top level Settings controller
 */
class SettingsController: UITableViewController {
    
    private var entityTypes = ["Sites", "Supervisors", "Species"]

    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.title = "Settings"
        self.tableView.register(SimpleTableViewCell.self, forCellReuseIdentifier: "basicStyle")
    }
    
    // MARK: - Datasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Entities"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entityTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = entityTypes[indexPath.item]
        return cell
    }
    
    // MARK: - Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch entityTypes[indexPath.item] {
        case "Sites":
            self.navigationController?.pushViewController(SitesController(), animated: true)
        case "Supervisors":
            self.navigationController?.pushViewController(SupervisorsController(), animated: true)
        case "Species":
            self.navigationController?.pushViewController(SpeciesController(), animated: true)
        default:
            break
        }
    }
    
}
