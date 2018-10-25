import UIKit
import Firebase

class ListTableViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ItemCell")
        tableView.dataSource = self
        return tableView
    }()
    
    // MARK: Constants
    let listToUsers = "ListToUsers"
    
    // MARK: Properties
    
    
    var items: [Item] = []
    var user: User!
//    var userCountBarButtonItem: UIBarButtonItem!
    let ref = Database.database().reference(withPath: "list-items")
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
//        tableView.allowsMultipleSelectionDuringEditing = false
        
//        userCountBarButtonItem = UIBarButtonItem(title: "1",
//                                                 style: .plain,
//                                                 target: self,
//                                                 action: #selector(userCountButtonDidTouch))
//        userCountBarButtonItem.tintColor = UIColor.white
//        navigationItem.leftBarButtonItem = userCountBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonDidTouch))
        
        user = User(uid: "FakeId", email: "dummy@gmail.com")
       
        ref.observe(.value, with: { snapshot in
            var newItems: [Item] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let listItem = Item(snapshot: snapshot) {
                    newItems.append(listItem)
                }
            }
            self.items = newItems
            self.tableView.reloadData()
        })
    }
    
    // MARK: Add Item
    
    @objc func addButtonDidTouch(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Leesta Item",
                                      message: "Add an Item",
                                      preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = alert.textFields?.first, let text = textField.text else { return }
            let listItem = Item(name: text, addedByUser: self.user.email, completed: false)
            let listItemRef = self.ref.child(text.lowercased())
            listItemRef.setValue(listItem.toAnyObject())
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addTextField()

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }
    
//    @objc func userCountButtonDidTouch() {
//        performSegue(withIdentifier: listToUsers, sender: nil)
//    }
}

extension ListTableViewController: UITableViewDataSource {

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return items.count
        }
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
            let listItem = items[indexPath.row]
            print(items)
            cell.textLabel?.text = listItem.name
//            cell.detailTextLabel?.text = listItem.addedByUser
            toggleCellCheckbox(cell, isCompleted: listItem.completed)
            return cell
        }
    
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .black
            cell.detailTextLabel?.textColor = .black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .gray
            cell.detailTextLabel?.textColor = .gray
        }
    }
}

extension ListTableViewController: UITabBarDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        var listItem = items[indexPath.row]
        let toggledCompletion = !listItem.completed
        
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        listItem.completed = toggledCompletion
        tableView.reloadData()
    }
}
