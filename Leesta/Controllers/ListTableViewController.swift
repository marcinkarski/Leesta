import UIKit
import Firebase

enum State {
    case expanded, minimized
}

class ListTableViewController: UIViewController {
    
    var items: [Item] = []
    let ref = Database.database().reference(withPath: "list-items")
    
    var runningAnimators = [Int: UIViewPropertyAnimator]()
    var progressWhenInterrupted: CGFloat = 0
    var viewState: State = .minimized
    
    lazy var width: CGFloat = { return self.view.frame.width}()
    lazy var topFrame: CGRect = { return CGRect(x: 0, y: 200, width: self.width, height: self.view.frame.height) }()
    lazy var bottomFrame: CGRect = { return CGRect(x: 0, y: self.view.frame.height - 50, width: self.width, height: self.view.frame.height) }()
    lazy var totalVerticalDistance: CGFloat = { self.bottomFrame.minY - self.topFrame.minY }()
    
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
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
//        textView.text = "Type in an item here"
        textView.delegate = self
        textView.font = UIFont.boldSystemFont(ofSize: 28)
        textView.textColor = .white
        textView.textAlignment = .center
        textView.backgroundColor = .clear
        return textView
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(saveButtonDidTouch), for: .touchUpInside)
        return button
    }()
    
    private lazy var bottomView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .orange
        view.layer.cornerRadius = 8
        return view
    }()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        setupNavigationBar()
        
        bottomView.frame = bottomFrame
        view.addSubview(bottomView)
        bottomView.addSubview(textView)
        bottomView.addSubview(saveButton)
        textView.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 10).isActive = true
        textView.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 50).isActive = true
        textView.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -10).isActive = true
        textView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor, constant: -200).isActive = true
        saveButton.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 20).isActive = true
        saveButton.centerXAnchor.constraint(equalTo: bottomView.centerXAnchor).isActive = true
        
        bottomView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bottomViewTapped)))
        bottomView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(bottomViewPanned)))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonDidTouch))
        
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        tableView.addGestureRecognizer(longpress)
        
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: locationInView)
        struct My {
            static var cellSnapshot : UIView? = nil
            static var cellIsAnimating : Bool = false
            static var cellNeedToShow : Bool = false
        }
        struct Path {
            static var initialIndexPath : IndexPath? = nil
        }
        switch state {
        case UIGestureRecognizer.State.began:
            if indexPath != nil {
                Path.initialIndexPath = indexPath
                let cell = tableView.cellForRow(at: indexPath!)
                My.cellSnapshot  = snapshotOfCell(cell!)
                var center = cell?.center
                My.cellSnapshot!.center = center!
                My.cellSnapshot!.alpha = 0.0
                tableView.addSubview(My.cellSnapshot!)
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    center?.y = locationInView.y
                    My.cellIsAnimating = true
                    My.cellSnapshot!.center = center!
                    My.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    My.cellSnapshot!.alpha = 0.98
                    cell?.alpha = 0.0
                }, completion: { (finished) -> Void in
                    if finished {
                        My.cellIsAnimating = false
                        if My.cellNeedToShow {
                            My.cellNeedToShow = false
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                cell?.alpha = 1
                            })
                        } else {
                            cell?.isHidden = true
                        }
                    }
                })
            }
        case UIGestureRecognizer.State.changed:
            if My.cellSnapshot != nil {
                var center = My.cellSnapshot!.center
                center.y = locationInView.y
                My.cellSnapshot!.center = center
                if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
                    items.insert(items.remove(at: Path.initialIndexPath!.row), at: indexPath!.row)
                    tableView.moveRow(at: Path.initialIndexPath!, to: indexPath!)
                    Path.initialIndexPath = indexPath
                }
            }
        default:
            if Path.initialIndexPath != nil {
                let cell = tableView.cellForRow(at: Path.initialIndexPath!)
                if My.cellIsAnimating {
                    My.cellNeedToShow = true
                } else {
                    cell?.isHidden = false
                    cell?.alpha = 0.0
                }
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    My.cellSnapshot!.center = (cell?.center)!
                    My.cellSnapshot!.transform = CGAffineTransform.identity
                    My.cellSnapshot!.alpha = 0.0
                    cell?.alpha = 1.0
                }, completion: { (finished) -> Void in
                    if finished {
                        Path.initialIndexPath = nil
                        My.cellSnapshot!.removeFromSuperview()
                        My.cellSnapshot = nil
                    }
                })
            }
        }
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }

    @objc func addButtonDidTouch(_ sender: AnyObject) {
        
        self.textView.becomeFirstResponder()
        
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: viewState, duration: 0.5)
        } else {
            runningAnimators.forEach { $1.isReversed = !$1.isReversed }
        }
        let alert = UIAlertController(title: "Add an item to your Leesta", message: nil, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = alert.textFields?.first, let text = textField.text else { return }
            let listItem = Item(name: text, completed: false)
            let listItemRef = self.ref.child(text.lowercased())
            listItemRef.setValue(listItem.toAnyObject())
        }
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
//        alert.addTextField()
//        alert.addAction(saveAction)
//        alert.addAction(cancelAction)
//        present(alert, animated: true, completion: nil)
    }
    
    @objc func saveButtonDidTouch(_ sender: AnyObject) {
        guard let text = textView.text else { return }
        let listItem = Item(name: text, completed: false)
        let listItemRef = self.ref.child(text.lowercased())
        listItemRef.setValue(listItem.toAnyObject())
        textView.text = ""
        
        self.view.endEditing(true)
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: viewState, duration: 0.5)
        } else {
            runningAnimators.forEach { $1.isReversed = !$1.isReversed }
        }
    }
    
    func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .minimized:
                    self.bottomView.frame = self.topFrame
                case .expanded:
                    self.bottomView.frame = self.bottomFrame
                }
            }
            
            let identifier = frameAnimator.hash
            frameAnimator.addCompletion { position in
                self.cleanup(animatorWithId: identifier, at: position)
            }
            
            frameAnimator.startAnimation()
            runningAnimators[identifier] = frameAnimator
        }
    }
    
    @objc func bottomViewPanned(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: bottomView)
        let verticalTranslation = viewState == .minimized ? -translation.y : translation.y
        let fraction = (verticalTranslation / totalVerticalDistance) + progressWhenInterrupted
        
        switch gesture.state {
        case .began:
            animateTransitionIfNeeded(state: viewState, duration: 0.5)
            
            runningAnimators.forEach { $1.pauseAnimation() }
            progressWhenInterrupted = runningAnimators.first?.value.fractionComplete ?? 0
        case .changed:
            self.view.endEditing(true)
            runningAnimators.forEach { $1.fractionComplete = fraction }
        case .ended:
            let velocity = gesture.velocity(in: bottomView)
            
            switch viewState {
            case .minimized:
                if velocity.y > -500 && fraction < 0.5 {
                    runningAnimators.forEach { $1.isReversed = !$1.isReversed }
                }
            case .expanded:
                if velocity.y < 500 && fraction < 0.5 {
                    runningAnimators.forEach { $1.isReversed = !$1.isReversed }
                }
            }
            
            runningAnimators.forEach { $1.continueAnimation(withTimingParameters: nil, durationFactor: 1) }
        default:
            break
        }
    }
    
    @objc func bottomViewTapped(gesture: UITapGestureRecognizer) {
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: viewState, duration: 0.5)
        } else {
            runningAnimators.forEach { $1.isReversed = !$1.isReversed }
        }
    }
    
    func cleanup(animatorWithId identifier: Int, at position: UIViewAnimatingPosition) {
        if position == .end {
            switch self.bottomView.frame {
            case self.bottomFrame:
                self.viewState = .minimized
            case self.topFrame:
                self.viewState = .expanded
            default:
                break
            }
        }
        self.runningAnimators.removeValue(forKey: identifier)
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
        tableView.deselectRow(at: indexPath, animated: false)
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

extension ListTableViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .white
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Type in an item here"
            textView.textColor = .white
        }
    }
}
