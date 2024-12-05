import UIKit
import Alamofire
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var users:[User] = []
    var dataUsers: [DataUsers] = []
    
    //для скролла
    var isLoading = false
    var currentPage = 1
    
 
    
    // interface
    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "GitHub Users"
        getAPI(currentPage)
        fetchData()

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
     
        tableView.contentInset.bottom = 20
        
        tableView.frame = view.bounds
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserCell")
        
        // автоматическая высота для ячеек
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100 // предполагаемая высота ячейки
        tableView.rowHeight = 100
        


    }


    func getAPI(_ pageNumb: Int) {
        guard !isLoading else {return }
        isLoading = true
        
        
        let url = "https://api.github.com/users?page=" + String(pageNumb)
        AF.request(url).responseJSON { response in
            switch response.result {
            case .success(let value):
        
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
                    let newUsers = try JSONDecoder().decode([User].self, from: data)
                    
                
                    if newUsers.isEmpty {
                        self.isLoading = false
                        print("THERE ARE NO NEW USERS")
                        return
                    }
                    
                    self.users.append(contentsOf: newUsers)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                              self.tableView.reloadData()
                              
                          }
                    
                    self.tableView.reloadData()
                    
                } catch {
                    print("ERROR!")
                }
                

                
                self.isLoading = false
 

                
            case .failure(_):
                print("json файл не распарсился")
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let threshold = CGFloat(100)
        
        if offsetY > contentHeight - scrollView.frame.height - threshold && !isLoading {
            currentPage += 1
            getAPI(currentPage)
        }
    }

    
 
    // загрузка данных из Core Data
    func fetchData() {
        do {
            dataUsers = try context.fetch(DataUsers.fetchRequest())
            self.tableView.reloadData()
        } catch {
            print("Ошибка при загрузке данных из Core Data")
        }
    }
    
    func save(user: User) {
        let fetchRequest: NSFetchRequest<DataUsers> = DataUsers.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %d", user.id)

        do {
            let results = try context.fetch(fetchRequest)
            if results.isEmpty {
    
                let newUser = DataUsers(context: context)
                newUser.login = user.login
                newUser.id = Int64(user.id)
                newUser.avatar_url = user.avatar_url
                newUser.followers_url = user.followers_url
                newUser.following_url = user.following_url
            } else {
                let existingUser = results.first!
                existingUser.login = user.login
                existingUser.avatar_url = user.avatar_url
                existingUser.followers_url = user.followers_url
                existingUser.following_url = user.following_url
            }
            
            try context.save()
            fetchData()
            
        } catch {
            print("Ошибка при сохранении пользовательских данных")
        }
    }

    
    func deleteUser(_ indexPath: IndexPath) {
        let userDelete = dataUsers[indexPath.row]
        context.delete(userDelete)
        
        do {
            try context.save()
            fetchData()
        } catch {
            print("Ошибка при сохранении пользовательских данных")
        }
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        let user = users[indexPath.row]

        cell.titleLabel.text = user.login
        cell.descriptionLabel.text = "followers: " + user.followers_url
        
        cell.userImageView.image = nil

        // Проверка URL изображения
        guard let url = URL(string: user.avatar_url) else {
            return cell
        }

        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let updateCell = tableView.cellForRow(at: indexPath) as? UserTableViewCell {
                            updateCell.userImageView.image = image
                        }
                    }
                }
            case .failure(_):
                print("Ошибка загрузки изображения")
            }
        }

        return cell
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteUser(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        let alertController = UIAlertController(title: "Edit", message: "Edit user info", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = user.login
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let newLogin = alertController.textFields?[0].text else { return }
            var editedUser = user
            editedUser.login = newLogin
            
            self?.save(user: editedUser)
            self?.fetchData()
        }
        alertController.addAction(saveAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
        
        
}
