import Foundation
import UIKit
import Resolver

/*
 Top level Settings controller
 */
class SettingsController: UITableViewController {
    
    @Injected private var sitesController: SitesController
    @Injected private var speciesController: SpeciesController
    @Injected private var supervisorsController: SupervisorsController
    
    private var entityTypes = ["Sites", "Supervisors", "Species"]
    private var apiProperties = [Constants.Http.protectEarthApiBaseUrl,
                                 Constants.Http.protectEarthEnvironmentName,
                                 Secrets.awsBucketName,
                                 "\(Secrets.awsAccessKey.prefix(4))************\(Secrets.awsAccessKey.suffix(4))",
                                 Secrets.awsBucketRegion]

    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.title = "Settings"
        self.tableView.register(SimpleTableViewCell.self, forCellReuseIdentifier: "basicStyle")
    }
    
    // MARK: - Datasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Entities"
        case 1:
            return "API"
        case 2:
            return "Device ID"
        default:
            return "Error"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return entityTypes.count
        case 1:
            return apiProperties.count
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        switch indexPath.section {
        case 0:
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = entityTypes[indexPath.item]
        case 1:
            cell.textLabel?.text = apiProperties[indexPath.item]
            cell.selectionStyle = .none
        case 2:
            cell.textLabel?.text = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            cell.selectionStyle = .none
        default:
            break
        }
        return cell
    }
    
    // MARK: - Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            switch entityTypes[indexPath.item] {
            case "Sites":
                self.navigationController?.pushViewController(sitesController, animated: true)
            case "Supervisors":
                self.navigationController?.pushViewController(supervisorsController, animated: true)
            case "Species":
                self.navigationController?.pushViewController(speciesController, animated: true)
            default:
                break
            }
        }
    }
    
}
