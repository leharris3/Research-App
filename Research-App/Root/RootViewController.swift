import UIKit
import FirebaseAuth
import FirebaseFirestore

class RootViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUser = Auth.auth().currentUser {
            print("--------------------------------------------------------------------------------------")
            print("Current user email: " + currentUser.email!)
            
            let email = currentUser.email ?? ""
            let db = Firestore.firestore()
            
            let ref = db.collection("profiles").document(email)
            ref.getDocument { (document, error) in
                if let error = error {
                    print("Error retrieving user profile: \(error.localizedDescription)")
                    return
                }
                if let document = document?.exists {
                    self.navigateToFeature()
                }
            }
        }
    }
    
    private func navigateToFeature() {
        DispatchQueue.main.async {
            let featureViewController = HomescreenViewController()
            let navigationController = HomescreenNavigationController(rootViewController: featureViewController)
            if let window = UIApplication.shared.windows.first {
                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = navigationController
                }, completion: nil)
            }
        }
    }
}
