import UIKit
import Firebase

class ListTableViewController: UIViewController {
    
    var items: [Item] = []
    var user: User!
    let ref = Database.database().reference(withPath: "list-items")
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .white
        tableView.separatorInset = .zero
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        setupNavigationBar()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonDidTouch))
        
        ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
            var newItems: [Item] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let groceryItem = Item(snapshot: snapshot) {
                    newItems.append(groceryItem)
                }
            }
            self.items = newItems
            self.tableView.reloadData()
        })
    }

    @objc func addButtonDidTouch(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Add an item to your Leesta",
                                      message: nil,
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = alert.textFields?.first, let text = textField.text else { return }
            let listItem = Item(name: text, completed: false)
            let listItemRef = self.ref.child(text.lowercased())
            listItemRef.setValue(listItem.toAnyObject())
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

extension ListTableViewController: UITableViewDataSource {

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return items.count
        }
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let listItem = items[indexPath.row]
            cell.textLabel?.text = listItem.name
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 28)
            cell.textLabel?.numberOfLines = 0
            cell.backgroundColor = .white
            toggleCellCheckbox(cell, isCompleted: listItem.completed)
            return cell
        }
    
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .orange
        } else {
            cell.accessoryType = .checkmark
            cell.tintColor = .lightGray
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        }
    }
}

extension ListTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let listItem = items[indexPath.row]
            listItem.ref?.removeValue()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let listItem = items[indexPath.row]
        let toggledCompletion = !listItem.completed
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        listItem.ref?.updateChildValues(["completed": toggledCompletion])
    }
}

extension ListTableViewController {
    
    private func setupNavigationBar() {
        self.title = "Leesta"
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = .orange
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.orange]
    }
}
