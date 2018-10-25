import UIKit

class TableViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = .white
    }
    
    private func setupNavigationBar() {
        self.title = "Leesta"
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .orange
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
    }
}
