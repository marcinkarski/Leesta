import UIKit

class ItemCell: UITableViewCell {
    
    var item: Item? {
        didSet {
            nameLabel.text = item?.name
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Loading user name..."
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .gray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        addSubview(nameLabel)
        
        NSLayoutConstraint.activate([nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0), nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0), nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0), nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)])
    }
    
    static var identifier: String {
        return String(describing: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
