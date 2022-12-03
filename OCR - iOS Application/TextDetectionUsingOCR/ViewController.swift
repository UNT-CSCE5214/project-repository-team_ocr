//
//  ViewController.swift
//  TextDetectionUsingOCR
//
//  Created by Sravanthi Kande on 12/2/22.
//

import UIKit
import Vision
import VisionKit

class ViewController: UIViewController {

    private var scanButton = UploadButton(frame: .zero)
    private var scanImageView = CustomImageView(frame: .zero)
    private var resultTextView = ResultTextView(frame: .zero, textContainer: nil)
    private var extractTextRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configureVisionOCR()
    }

    
    private func configure() {
        view.addSubview(scanImageView)
        view.addSubview(resultTextView)
        view.addSubview(scanButton)
        
        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            scanButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            scanButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            scanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            
            resultTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            resultTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            resultTextView.bottomAnchor.constraint(equalTo: scanButton.topAnchor, constant: -padding),
            resultTextView.heightAnchor.constraint(equalToConstant: 250),
            
            scanImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            scanImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            scanImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            scanImageView.bottomAnchor.constraint(equalTo: resultTextView.topAnchor, constant: -padding)
        ])
        scanButton.addTarget(self, action: #selector(imagePickerBtnAction), for: .touchUpInside)
    }
    
    
    private func scanDocument() {
        let scanVC = VNDocumentCameraViewController()
        scanVC.delegate = self
        present(scanVC, animated: true)
    }

    @objc func imagePickerBtnAction(selectedButton: UIButton)
    {
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.scanDocument()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }

    func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        resultTextView.text = ""
        scanButton.isEnabled = false
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([self.extractTextRequest])
        } catch {
            print(error)
        }
    }

    
    private func configureVisionOCR() {
        extractTextRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var ocrText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                
                ocrText += topCandidate.string + "\n"
            }
            
            
            DispatchQueue.main.async {
                self.resultTextView.text = ocrText
                self.scanButton.isEnabled = true
            }
        }
        
        extractTextRequest.recognitionLevel = .accurate
        extractTextRequest.recognitionLanguages = ["en-US", "en-GB"]
        extractTextRequest.usesLanguageCorrection = true
    }
}


extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        scanImageView.image = scan.imageOfPage(at: 0)
        processImage(scan.imageOfPage(at: 0))
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        //Handle properly error
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.scanImageView.image = image
            self.processImage(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
