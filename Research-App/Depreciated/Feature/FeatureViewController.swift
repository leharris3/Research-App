//
//  FeatureViewController.swift
//  Research-App
//
//  Created by Levi Harris on 2/25/23.
//

import UIKit
import SwiftUI
import FirebaseAuthUI
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

class FeatureViewController: UIViewController {
    
    // TODO: Batch profile loading.
        // On inital load
    
    // Scroll profile description.
    @IBOutlet weak var profileDescriptionScrollView: UIScrollView!
    
    // Height of profile description scroll view.
    @IBOutlet weak var profileDescriptionHeightConstraint: NSLayoutConstraint!
    
    // Current image indicator connection.
    @IBOutlet weak var profileCurrentImageIndicator: UIStackView!
    
    // Connections to current profile bio fields.
    @IBOutlet weak var profileBioName: UIView!
    @IBOutlet weak var profileBioNameLabel: UILabel!
    @IBOutlet weak var profileBioAge: UILabel!
    @IBOutlet weak var profileBioInterestsList: UILabel!
    @IBOutlet weak var profileBioAboutMe: UILabel!
    
    // Navigation views of top profile.
    @IBOutlet weak var leftImageArea: UIView!
    @IBOutlet weak var draggableArea: UIView!
    @IBOutlet weak var rightImageArea: UIView!
    
    // Show more button.
    @IBOutlet weak var showMoreButton: UIButton!
    
    // Hide description.
    @IBOutlet weak var hideDescriptionButton: UIButton!
    
    // Container.
    @IBOutlet weak var contentView: UIView!
    
    // Connections to top profile.
    @IBOutlet weak var topProfile: UIView!
    @IBOutlet weak var topProfileCurrentImage: UIImageView!
    
    // Connections to bottom profile.
    @IBOutlet weak var bottomProfile: UIView!
    
    // Bio scroll view.
    @IBOutlet weak var bioScrollView: UIScrollView!
    
    // Bio is / is not visible.
    private var scrollViewHeightVisable: NSLayoutConstraint? = nil
    private var scrollViewHeightInvisible: NSLayoutConstraint? = nil
    
    // Var to enable/disable dragging animations of top profile view..
    private var isDragging: Bool = false
    
    // Profile swiping disabled on description display.
    private var swipingIsEnabled: Bool = true
    
    // Flag that indicates inital profile loading has not occured, both a top and bottom profile must be loaded.
    private var initialProfilesLoaded: Bool = false
    
    // Current batch of loaded profile dictionaries.
    private var profileBatch: [[String: Any]] = []
    
    // Current dictionary assoictaed with loaded profile at top of profile stack.
    private var topProfileData: [String: Any] = [:]
    
    // Images assoicated w/ a profile.
    private var topProfileImages: [UIImage] = []
    
    // Current profile fields.
    private var currentUserData: (Any)? = nil
    private var currentUserEmail: String = ""
    private var currentUserPreference: String = ""
    private var seenProfiles: [String] = []
    private var unseenProfiles: [String] = []
    
    // Active user pools.
    private var malePool: [String] = []
    private var femalePool: [String] = []
    private var totalPool: [String] = []

    // Profile animation constants.
    var profileBounds: CGRect? = nil
    
    var startingX: CGFloat = 0.0
    var startingY: CGFloat = 0.0

    var relativeX: CGFloat = 0
    var relativeY: CGFloat = 0
    
    var maxHeight: CGFloat = 0.0
    var minHeight: CGFloat = 0.0
    
    var maxWidth: CGFloat = 0.0
    var minWidth: CGFloat = 0.0
    
    var deltaX: CGFloat = 0.0
    var deltaY: CGFloat = 0.0
    
    var screenWidth: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeVariables() // Initalize vars, constants, and flags.
    }
    
    // Initalize vars and constants.
    private func initializeVariables() {
        
        // Initalize bio height constraints.
        scrollViewHeightVisable = profileDescriptionHeightConstraint
        scrollViewHeightInvisible = profileDescriptionHeightConstraint.constraintWithMultiplier(0.0)
            
        // Initalize a var equal to default bounds of the visible profile.
        profileBounds = topProfile.bounds
        
        // Interaction w/ bottom profile disabled by default.
        bottomProfile.isUserInteractionEnabled = false
        
        topProfile.layer.cornerRadius = 30
        bottomProfile.layer.cornerRadius = 30
        
        // Set max height and width of visible profile view.
        maxHeight = topProfile.frame.origin.y + 30
        minHeight = topProfile.frame.origin.y - 20
        
        maxWidth = topProfile.frame.midX + 100.00
        minWidth = topProfile.frame.midX - 100.00
        
        // Set starting coords for animating profile view on user touch-drag.
        startingX = topProfile.frame.origin.x
        startingY = topProfile.frame.origin.y
        
        // Initalize a var equal to total screen width.
        screenWidth = view.bounds.width
        
        UIView.animate(withDuration: 0.25, delay: 0.25, animations: { [self] in
            // Set a thin border around uuser bios
            self.profileDescriptionScrollView.layer.borderWidth = 1
            self.profileDescriptionScrollView.layer.borderColor = UIColor.darkGray.cgColor
                
            // Hide bio button is invisble and disabled by default.
            self.hideDescriptionButton.alpha = 0.0
            self.hideDescriptionButton.isUserInteractionEnabled = false
            
            // Set bio to a default height of "invisible".
            self.profileDescriptionScrollView.removeConstraint(self.profileDescriptionHeightConstraint!)
            self.profileDescriptionScrollView.addConstraint(scrollViewHeightInvisible!)
        }, completion: nil)
        
        
        // Initialize user pool data.
        let db = Firestore.firestore()
        let poolsRef = db.collection("users").document("user-lists")
        
        poolsRef.getDocument {(doc, err) in
            if let doc = doc, doc.exists {
                self.malePool = doc.data()!["male-users"] as! [String]
                self.femalePool = doc.data()!["female-users"] as! [String]
                self.totalPool = doc.data()!["all-users"] as! [String]
                
                print("------------------------------------------------------------")
                print("User pools loaded: ")
                print(self.malePool)
                print(self.femalePool)
                print(self.totalPool)
                
                // Load current user variables.
                self.loadCurrentUser()
            }
        }
    }
    
    // Initalize vars assoicated with current user.
    private func loadCurrentUser() {
        
        print("")
        print("------------------------------------------------------------")
        print("Loading current user profile from firebase.")
        
        let currentUser = Auth.auth().currentUser
        if (currentUser == nil) {
            print("Error retrieving current user.")
            return
        } // Error.
        
        currentUserEmail = currentUser!.email!
        var currentUserProfile: [String: Any]? = nil
            
        // Create a reference to user-profile.
        let db = Firestore.firestore()
        let ref = db.collection("users").document("user-profiles")
        
        // Get current user profile.
        ref.getDocument { (document, error) in
            if let document = document, document.exists {
                
                currentUserProfile = document.data()![self.currentUserEmail] as! [String : Any]
                if (currentUser == nil) {return}
                
                // Set current profile vars from DB.
                self.currentUserData = currentUserProfile
                self.currentUserPreference = currentUserProfile!["preference"] as! String
                self.seenProfiles = currentUserProfile!["seen_profiles"] as! [String]
                
                // Add new users to unseen_profiles pool.
                var allProfiles: [String] = []
                
                if (self.currentUserPreference == "M") {
                    allProfiles = self.malePool
                    self.unseenProfiles = allProfiles.filter { !self.seenProfiles.contains($0) }
                }
                else if (self.currentUserPreference == "W"){
                    allProfiles = self.femalePool
                    self.unseenProfiles = allProfiles.filter { !self.seenProfiles.contains($0) }
                }
                else {
                    allProfiles = self.totalPool
                    self.unseenProfiles = allProfiles.filter { !self.seenProfiles.contains($0) }
                }
                
                print("Unseen profiles loaded:")
                print(self.unseenProfiles)
                
                print("current user email: " + self.currentUserEmail)
                
                // Push a new profile to the top of the user stack.
                Task.init{
                    await self.pushProfile()
                }
                
            } else {
                print("Document does not exist")
            }
        }
        print("------------------------------------------------------------")
    }
    
    // MARK: Push bottom profile to top and load a new bottom profile.
    private func pushProfile() async {
        
        print("------------------------------------------------------------")
        print("Pushing new profile to top of stack.")
        
        if (profileBatch.count == 0) {
            await loadProfileBatch()
        }
        
        await loadNewTopProfileView()
        await loadNewBottomProfileView()
        
        print("------------------------------------------------------------")
        print("")
    }
    
    // Load a new batch of profiles from database.
    private func loadProfileBatch() async {
        
        print("------------------------------------------------------------")
        print("Loading new batch of profiles.")
        
        for i in 0...4 {
            if (unseenProfiles.count == 0) {
                print("No more unseen profiles to load.")
                return
            }
            else {
                await popProfile()
            }
        }
        
        print("Loading complete, loaded profile batch: ")
        print(self.profileBatch)
    }
    
    // MARK: Loads a new visible, top profile from profile batch.
    private func loadNewTopProfileView() async {
        
        print("------------------------------------------------------------")
        print("Loading top profile.")
        
        if (profileBatch.count == 0) {
            await loadProfileBatch()
        }
        
        // Out of profiles.
        if (profileBatch.count == 0) {
            return
        }
    
        let newProfileData: [String: Any] = profileBatch.popLast()!
        let newProfileEmail: String = newProfileData["email"]! as! String
        
        print("Loading new profile with email: " + newProfileEmail)
        
        await loadNewImageSet(email: newProfileEmail)
        loadProfileBiography(profileData: newProfileData)
        
    }
    
    // Loads a new bottom profile image.
    private func loadNewBottomProfileView() async {
        
        print("------------------------------------------------------------")
        print("Loading bottom profile...")
        
        if (profileBatch.count == 0) {
            await loadProfileBatch()
        }
        
        // Profile data popped from top of profile stack.
        var newProfileData: (Any) = profileBatch.last
    }
    
    // Load the bio associated with a current profile at the top of the profile stack.
    private func loadProfileBiography(profileData: [String: Any]){
        
        print("------------------------------------------------------------")
        print("Loading new bio.")
        
        print(profileData)
        
        self.profileBioNameLabel.text = String(profileData["first_name"] as! String) + " "
        self.profileBioAge.text = String(profileData["age"] as! Int)
        self.profileBioAboutMe.text = String(profileData["about_me"] as! String)
    }
    
    // Loads a new set of images assoictaed with the email of the current top profile.
    private func loadNewImageSet(email: String) async {
        
        print("------------------------------------------------------------")
        print("Loading new image set for top profile.")
        
        let storage = Storage.storage()
        let quotedEmail = #"""# + email + #"""#
        let gsReference = storage.reference(forURL: #"gs://research-app-8f87d.appspot.com/images/Optional("clara-f@email.unc.edu")/4C86259D-0E13-4AE1-A947-BEAAE2A342AB"#)
        
        print(gsReference.fullPath)
            
        let reference = gsReference.getData(maxSize: 1024 * 1024 * 1024, completion: { (data, error) in
            print("Attempting to get images... ")
            print(quotedEmail)  
            if (error != nil) {
                print(error?.localizedDescription)
                print("Error")
                return
            }
            print(data)
        })
        
        print(reference)

        // UIImageView in your ViewController
//        let imageView: UIImageView = UIImageView()
//
//        // Placeholder image
//        let placeholderImage = UIImage(named: "placeholder.jpg")
//
//        // Load the image using SDWebImage
//        topProfileCurrentImage.sd_setImage(with: reference, placeholderImage: placeholderImage)
        
    }
    
    // Gets profile of user from unseen profile stack.
    func popProfile() async -> Void {
        
        print("------------------------------------------------------------")
        print("Popping profile.")
        
        let db = Firestore.firestore()
        let ref = db.collection("users").document("user-profiles")
        var doc: DocumentSnapshot?
            
        
            do {
                doc = try await ref.getDocument()
            }
            catch {
                print("Error getting user profile")
                return
            }
            
        if doc!.exists {
            if self.unseenProfiles.count == 0 {
                print("No more unseen profiles")
            }
            
            let unseenUserEmail: String = (self.unseenProfiles.popLast()! as String?)!
            print("Geting unseen user: " + unseenUserEmail)
            
            let profile =  doc!.data()![unseenUserEmail] as! [String : Any]
            self.profileBatch.append(profile)
            self.seenProfiles.append(unseenUserEmail)
        }
    }
    
    // Set origin of the visible profile view.
    func setOrigin(x: CGFloat, y: CGFloat) {
        topProfile.frame.origin.x = x
        topProfile.frame.origin.y = y
    }
    
    // Return profile to center of screen.
    func returnToCenter() {
        
        let distanceX: CGFloat = CGFloat(startingX) - topProfile.frame.origin.x
        let distanceY: CGFloat = CGFloat(startingY) - topProfile.frame.origin.y
        
        UIView.animate(withDuration: 0.15, delay: 0.0, animations: {
            self.topProfile.frame.origin.x = CGFloat(self.startingX)
            self.topProfile.frame.origin.y = CGFloat(self.startingY)
        })
    }
    
    // MARK: Make profile description visible with animation.
    @IBAction func showMorePressed(_ sender: Any) {
        swipingIsEnabled = false
        profileDescriptionScrollView.removeConstraint(scrollViewHeightInvisible!)
        profileDescriptionScrollView.addConstraint(scrollViewHeightVisable!)
        UIView.animate(withDuration: 0.15, delay: 0.0, animations: {
            self.view.layoutIfNeeded()
            self.showMoreButton.alpha = 0.0
            self.showMoreButton.isUserInteractionEnabled = false
            self.hideDescriptionButton.alpha = 1.0
            self.hideDescriptionButton.isUserInteractionEnabled = true
        })
    }

    // Hide profile description.
    @IBAction func hideDescriptionPressed(_ sender: Any) {
        print("pressed")
        swipingIsEnabled = true
        profileDescriptionScrollView.removeConstraint(scrollViewHeightVisable!)
        profileDescriptionScrollView.addConstraint(scrollViewHeightInvisible!)
        UIView.animate(withDuration: 0.15, delay: 0.0, animations: {
            self.view.layoutIfNeeded()
            self.showMoreButton.alpha = 1.0
            self.showMoreButton.isUserInteractionEnabled = true
            self.hideDescriptionButton.alpha = 0.0
            self.hideDescriptionButton.isUserInteractionEnabled = false
        })
    }
}

extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self.firstItem!, attribute: self.firstAttribute, relatedBy: self.relation, toItem: self.secondItem, attribute: self.secondAttribute, multiplier: multiplier, constant: self.constant)
    }
}

// TODO: Redo Navigatiomn
extension FeatureViewController {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !(swipingIsEnabled) {return}
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: view)
        let absoluteLocation = touch.location(in: view)
        
        // Set relative coords.
        relativeX = absoluteLocation.x
        relativeY = absoluteLocation.y
        
        print(location)
        
        if (topProfile.bounds.contains(location)) {
            if (leftImageArea.bounds.contains(location)){
                print("Display previous image.")
            }
            else if (rightImageArea.bounds.contains(location)) {
                print("Display next image.")
            }
            else{
                print("Dragging.")
                isDragging = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !(swipingIsEnabled) {return}
        
        // Prev coords.
        let prevX = topProfile.frame.origin.x
        let prevY = topProfile.frame.origin.y
        
        guard isDragging, let touch = touches.first else {
            return
        }
        
        // Location.
        let location = touch.location(in: view)
        
        // Set new X.
        topProfile.frame.origin.x += location.x - CGFloat(relativeX)
        
        let candidateHeight: CGFloat = topProfile.frame.origin.y + location.y - relativeY
        
        // Set new Y.
        if (candidateHeight > maxHeight) {
            topProfile.frame.origin.y = maxHeight
        }
        else if (candidateHeight < minHeight) {
            topProfile.frame.origin.y = minHeight
        }
        else {
            topProfile.frame.origin.y = candidateHeight
        }
        
        // New coords.
        let newX = topProfile.frame.origin.x
        let newY = topProfile.frame.origin.y
        
        // Set deltas.
        deltaX = newX - prevX
        deltaY = newY - prevY
        
        // Set relative coords.
        relativeX = location.x
        relativeY = location.y
        
        let distance = abs(view.frame.midX - topProfile.frame.midX) // Calculate distance from origin.
        let ratio = distance / (screenWidth / 2) // % moved towards a horizontal edge.
        
        // topProfile.alpha = 1 - ( CGFloat(ratio) * (1 / 2)  )
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !(swipingIsEnabled) {return}
        
        // TODO: Single Tap Gesture Recognizer
            // Change picture.
            // If a touch begins and ends on the same coordinate, it is considered a tap.
        
        // TODO: Double Tap Gesture Recognizer
            // Like animation and prompt.
            // On touch begins,
        
        // Calculate velocity of swipe.
        let velocityX: CGFloat = deltaX
        let velocityY: CGFloat = deltaY
        let directionIndependentVelocity: CGFloat = hypot(velocityX, velocityY)
        
        let distanceToMaxEdge = self.topProfile.bounds.maxX
        let distanceToMinEdge = self.maxWidth - self.topProfile.bounds.minX
        
        // print(directionIndependentVelocity)

        // MARK: Dismiss
        if (topProfile.frame.midX < minWidth || topProfile.frame.midX > maxWidth) {
            
            if (directionIndependentVelocity > 2.5) {
                // print("Swipe out")
                
                // Swipe out left / right
                if (velocityX < 0) {
                    // Swipe right
                    UIView.animate(withDuration: 0.2, delay: 0.0, animations: {
                        self.topProfile.frame.origin.x -= distanceToMaxEdge
                    }, completion: {(finished: Bool) in
                        Task.init{
                            await self.pushProfile()
                        }
                        self.topProfile.frame.origin.x = self.startingX
                        self.topProfile.frame.origin.y = self.startingY
                    })
                }
                else {
                    UIView.animate(withDuration: 0.2, delay: 0.0, animations: {
                        self.topProfile.frame.origin.x += distanceToMinEdge
                    }, completion: {(finished: Bool) in
                        Task.init{
                            await self.pushProfile()
                        }
                        self.topProfile.frame.origin.x = self.startingX
                        self.topProfile.frame.origin.y = self.startingY
                    })
                }
            }
            else {
                returnToCenter()
            }
        }
        else {
            returnToCenter()
        }
    }
}
    
