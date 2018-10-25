import Foundation
import Firebase

struct Item {
  let ref: DatabaseReference?
  let key: String
  let name: String
  var completed: Bool
  
  init(name: String, completed: Bool, key: String = "") {
    self.ref = nil
    self.key = key
    self.name = name
    self.completed = completed
  }
  
  init?(snapshot: DataSnapshot) {
    guard
      let value = snapshot.value as? [String: AnyObject],
      let name = value["name"] as? String,
      let completed = value["completed"] as? Bool else {
      return nil
    }
    
    self.ref = snapshot.ref
    self.key = snapshot.key
    self.name = name
    self.completed = completed
  }
  
  func toAnyObject() -> Any {
    return [
      "name": name,
      "completed": completed
    ]
  }
}
