//
//  BioMediaViewController.swift
//  Research-App
//
//  Created by Levi Harris on 3/11/23.
//

import UIKit
import YPImagePicker
import FirebaseStorage

class BioMediaViewController: UIViewController {

    @IBOutlet weak var imageOne: UIButton!
    @IBOutlet weak var imageTwo: UIButton!
    @IBOutlet weak var imageThree: UIButton!
    @IBOutlet weak var imageFour: UIButton!
    @IBOutlet weak var imageFive: UIButton!
    @IBOutlet weak var imageSix: UIButton!
    @IBOutlet weak var imageSeven: UIButton!
    @IBOutlet weak var imageEight: UIButton!
    @IBOutlet weak var imageNine: UIButton!
    
    // Photo button -> image Data map.
    var photosToUpload: [Data?] = [nil, nil, nil, nil, nil, nil, nil, nil, nil]
    let MAX_IMAGE_SIZE: Int = 166666
    
    // Custom config.
    var config: YPImagePickerConfiguration = {
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = false
        config.usesFrontCamera = true
        config.showsPhotoFilters = false
        config.showsVideoTrimmer = false
        config.shouldSaveNewPicturesToAlbum = true
        config.albumName = "New Album"
        config.startOnScreen = YPPickerScreen.library
        config.screens = [.library, .photo]
        config.showsCrop = .none
        config.targetImageSize = YPImageSize.original
        config.overlayView = UIView()
        config.hidesStatusBar = true
        config.hidesBottomBar = false
        config.hidesCancelButton = false
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        return config
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func compressImage(image: UIImage, toSizeInBytes sizeInBytes: Int) -> UIImage? {
        let targetSize = CGSize(width: 1024, height: 1024)
        var compressionQuality: CGFloat = 1.0
        let maxCompressionQuality: CGFloat = 0.1
        
        // Check if image is already smaller than target size
        if let imageData = image.jpegData(compressionQuality: 1.0),
           imageData.count < sizeInBytes {
            return UIImage(data: imageData)
        }
        
        // Binary search to find the optimal compression quality
        var compressedImageData: Data?
        var left: CGFloat = maxCompressionQuality
        var right: CGFloat = 1.0
        
        while left <= right {
            let mid = (left + right) / 2.0
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let scaledImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            compressedImageData = scaledImage.jpegData(compressionQuality: mid)
            if let data = compressedImageData, data.count <= sizeInBytes {
                break
            } else if let data = compressedImageData, data.count > sizeInBytes {
                print(data.count)
                right = mid - 0.01
            } else {
                left = mid + 0.01
            }
        }
        
        if let data = compressedImageData {
            return UIImage(data: data)
        }
        return nil
    }
    
    // Display image select.
    func displayImageSelector(button: UIButton, imageNumber: Int) {
        // Image picker
        let picker = YPImagePicker(configuration: config)
        picker.didFinishPicking { [unowned picker] items, _ in
            if let photo = items.singlePhoto {
                
                // Set image in set.
                self.photosToUpload[imageNumber - 1] = photo.image.jpegData(compressionQuality: 0.8)
                
                // Set uploaded image as thumbnail.
                let targetSize = CGSize(width: 300, height: 300)
                let scaledImage = photo.image.scalePreservingAspectRatio(targetSize: targetSize)
                button.setImage(scaledImage, for: .normal)
                button.layer.cornerRadius = 20
                button.layer.borderColor = UIColor.black.cgColor
                button.layer.borderWidth = 1
                
                // Refresh views.
                self.viewDidLayoutSubviews() // Refresh views
            }
            
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
    }
    
    // Upload image button pressed.
    @IBAction func imageOnePressed(_ sender: Any) {
        // Upload photo + display thumbnail.
        displayImageSelector(button: imageOne!, imageNumber: 1)
    }
    
    @IBAction func imageTwoPressed(_ sender: Any) {
        displayImageSelector(button: imageTwo!, imageNumber: 2)
    }
    
    @IBAction func imageThreePressed(_ sender: Any) {
        displayImageSelector(button: imageThree!, imageNumber: 3)
    }
    
    @IBAction func imageFourPressed(_ sender: Any) {
        displayImageSelector(button: imageFour!, imageNumber: 4)
    }
    
    @IBAction func imageFivePressed(_ sender: Any) {
        displayImageSelector(button: imageFive!, imageNumber: 5)
    }
    
    @IBAction func imageSixPressed(_ sender: Any) {
        displayImageSelector(button: imageSix!, imageNumber: 6)
    }
    
    @IBAction func imageSevenPressed(_ sender: Any) {
        displayImageSelector(button: imageSeven!, imageNumber: 7)
    }
    
    @IBAction func imageEightPressed(_ sender: Any) {
        displayImageSelector(button: imageEight!, imageNumber: 8)
    }
    
    @IBAction func imageNinePressed(_ sender: Any) {
        displayImageSelector(button: imageNine!, imageNumber: 9)
    }
    
    @IBAction func continuePressed(_ sender: Any) {
        
        GlobalConstants.user.profilePhotos = [] // Should always be blank.
        
        // Upload photos.
        for photo in photosToUpload {
            if (photo != nil) {
                if let image = UIImage(data: photo!) {
                    if let compressedPhoto = self.compressImage(image: image, toSizeInBytes: MAX_IMAGE_SIZE) {
                        GlobalConstants.user.profilePhotos.append(compressedPhoto.jpegData(compressionQuality: 1.0)!)
                    }
                }
            }
        }
        
        // MARK: Onboarding complete, attempt to upload profile.
        let profileUploader = ProfileUploader()
        if (profileUploader.upload()) {
            
            // Media -> Enable Notifications.
            let enableNotifications = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EnableNotificationsViewController") as! EnableNotificationsViewController
            UIApplication.shared.windows.first?.rootViewController = enableNotifications
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            
            // Animate Feature Transition
            let options: UIView.AnimationOptions = .transitionCrossDissolve
            let duration: TimeInterval = 0.3
            UIView.transition(with: UIApplication.shared.keyWindow!, duration: duration, options: options, animations: {}, completion: nil)
        }
    }
}

// Scale image extension.
extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        return scaledImage
    }
}
