import UIKit

class TableViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
    }
    
    private func setupTableView() {
        view.backgroundColor = .white
        view.addSubview(tableView)
    }
    
    private func setupNavigationBar() {
        self.title = "Leesta"
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .orange
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
    }
}
