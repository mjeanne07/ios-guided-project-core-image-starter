import UIKit
import CoreImage
import Photos
import CoreImage.CIFilterBuiltins

class PhotoFilterViewController: UIViewController {

	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!

    private let context = CIContext(options: nil)

    //when choosing image put it in the originalImage
    var originalImage: UIImage? {
        didSet {
            // we want to scale down the image to make it easier to filter until the user is ready to save the image.
            guard let image = originalImage else { return }

            // height and width of the image view
            var scaledSize = imageView.bounds.size

            // 1, 2 or 3, depending on display (screen that we are using) the pixels and points can be different
            // ask the screen what the scale is
            let scale = UIScreen.main.scale

            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)

            // 'imageByScaling' is coming from UIImage+Scaling.swift
            let scaledImage = image.imageByScaling(toSize: scaledSize)

            self.scaledImage = scaledImage
        }
    }
    var scaledImage: UIImage? {
        didSet {
            imageView.image = scaledImage
        }
    }

	
	override func viewDidLoad() {
		super.viewDidLoad()

        originalImage = imageView.image

	}
	
	// MARK: Actions
	
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
		// TODO: show the photo picker so we can choose on-device photos
		// UIImagePickerController + Delegate
        presentImagePicker()

	}
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {
		// TODO: Save to photo library

        guard let originalImage = originalImage else { return }

        let filteredImage = image(byFiltering: originalImage)

        // Request permission from user to access and save photos, need to add in info plist privacy
        // authorization stored
        PHPhotoLibrary.requestAuthorization { (status) in

            guard status == .authorized else {
                NSLog("The user has not authorized permission for photo library usage.")
                // in real app, would need to present an alert so they could changed their settings
                return
            }

            // lets you create a PHAsset that takes image data and turns it into an asset so you can save it, needs to be created in this change block
            // need to manually keep the metadata if needed
            PHPhotoLibrary.shared().performChanges({

                // Make a new photo asset request
                PHAssetCreationRequest.creationRequestForAsset(from: filteredImage)

            }) { (success, error) in
                if let error = error {
                    NSLog("Error saving photo asset: \(error)")
                    return
                }
                // present alert to user that image was successfully saved.
            }

        }

	}
	

	// MARK: Slider events
	
	@IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
	}
	
	@IBAction func contrastChanged(_ sender: Any) {
        updateImage()
	}
	
	@IBAction func saturationChanged(_ sender: Any) {
        updateImage()
	}

    // MARK: - Image Filtering

    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = image(byFiltering: scaledImage)
        } else {
            imageView.image = nil
        }
    }

    private func image(byFiltering image: UIImage) -> UIImage {

        // UIImage -> CGIMAGE -> CIImage "recipe"
        // going straght from UI to CI is flaky.

        guard let cgImage = image.cgImage else { return image}

        let ciImage = CIImage(cgImage: cgImage)

        // Create the color controls filters both ways and set the appropriate values to the slider's values.
        // ciImage is going to be the input image

        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(ciImage, forKey: "inputImage")
        filter.setValue(saturationSlider.value, forKey: "inputSaturation")
        filter.setValue(brightnessSlider.value, forKey: "inputBrightness")
        filter.setValue(contrastSlider.value, forKey: "inputContrast")

        let filter2 = CIFilter.colorControls()
        filter2.inputImage = ciImage
        filter2.saturation = saturationSlider.value
        filter2.brightness = brightnessSlider.value
        filter2.contrast = contrastSlider.value

        // Remember that CIImage is just a recipe, not the actual image
        guard let outputImage =  filter.outputImage else { return image }

        // This is whhere the image filtering actually happens (where the graphics processor will perform the filter)
        // context is a canvas that we can use to render the image
        // CGRect is to clarify how much of the image you want to filter, .extent is the entire image bounds
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return image }

        return UIImage(cgImage: outputCGImage)

    }

    // MARK: - Private Functions

    func presentImagePicker() {

        // simulators dont have cameras, make sure the photo library is available to use in the first place
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            NSLog("The photo library is not available")
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self

        // imagePicker is just an apple view controller
        present(imagePicker, animated: true, completion: nil)

    }

}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let selectedImage = info[.originalImage] as? UIImage {
            originalImage = selectedImage
        }

        dismiss(animated: true, completion: nil)

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
         dismiss(animated: true, completion: nil)
    }
}

