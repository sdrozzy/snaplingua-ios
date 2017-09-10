//
//  SnapViewController.swift
//  snaplingua-ios
//
//  Created by Samuel Drozdov on 9/9/17.
//  Copyright © 2017 SnapLingua. All rights reserved.
//

import UIKit
import AVFoundation

class SnapViewController: UIViewController, AVCapturePhotoCaptureDelegate, GCImageRequestManagerDelegate {
  
  @IBOutlet weak var captureButton: UIButton!
  @IBOutlet weak var previewView: UIView!
  @IBOutlet weak var focusAreaView: UIView!
  @IBOutlet weak var captureActivityIndicator: UIActivityIndicatorView!
  
  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var capturePhotoOutput: AVCapturePhotoOutput?
  
  var imageRequestManager: GVImageRequestManager?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imageRequestManager = GVImageRequestManager()
    imageRequestManager?.delegate = self
    
    captureButton.clipsToBounds = true
    captureButton.backgroundColor = UIColor.init(white: 1.0, alpha: 0.3)
    captureButton.layer.cornerRadius = captureButton.bounds.width / 2
    captureButton.layer.borderWidth = 4
    captureButton.layer.borderColor = UIColor.white.cgColor
    
    focusAreaView.layer.borderWidth = 1
    focusAreaView.layer.borderColor = UIColor.init(white: 1.0, alpha: 0.3).cgColor
        
    self.enableCamera()
  }
  
  func startCaptureAnimation() {
    UIView.animate(withDuration: 0.3, animations: {
      self.captureButton.layer.opacity = 0
    }) { (true) in
      self.captureActivityIndicator.startAnimating()
    }
  }
  
  func endCaptureAnimation() {
    UIView.animate(withDuration: 0.3, animations: {
      self.captureButton.layer.opacity = 1
    }) { (true) in
      self.captureActivityIndicator.stopAnimating()
    }
  }
  
  @IBAction func pressedCancelButton(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func pressedCaptureButton(_ sender: UIButton) {
    self.startCaptureAnimation()
    
    guard let capturePhotoOutput = self.capturePhotoOutput else { return }
    
    let photoSettings = AVCapturePhotoSettings()
    photoSettings.isAutoStillImageStabilizationEnabled = true
    photoSettings.isHighResolutionPhotoEnabled = true
    photoSettings.flashMode = .auto
    
    capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
  }
  
  func requestCompleted(_ manager: GVImageRequestManager, responseStatus: String, labels: NSArray) {
    self.endCaptureAnimation()
    
    if responseStatus == GVImageResponseStatus.RequestSucceededButUncertainLabels {
      let alert = UIAlertController(title: "Couldn't Identify Object", message: "Please take another photo.", preferredStyle: UIAlertControllerStyle.alert)
      alert.show(self, sender: self)
    }
    else if responseStatus == GVImageResponseStatus.RequestFailed {
      let alert = UIAlertController(title: "Request Failed", message: "Please check you internet connection and try again.", preferredStyle: UIAlertControllerStyle.alert)
      alert.show(self, sender: self)
    }
    else if responseStatus == GVImageResponseStatus.RequestSucceeded {
      print(labels)
    }
    
  }

  
  func capturedImage(image: UIImage) {
    
    let binaryImageData = imageRequestManager?.base64EncodeImage(image)
    imageRequestManager?.createRequest(with: binaryImageData!)

    DLog(message: "capturedImage")
  }
  
  func capture(_ captureOutput: AVCapturePhotoOutput,
               didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
               previewPhotoSampleBuffer: CMSampleBuffer?,
               resolvedSettings: AVCaptureResolvedPhotoSettings,
               bracketSettings: AVCaptureBracketedStillImageSettings?,
               error: Error?) {
    
    guard error == nil, let photoSampleBuffer = photoSampleBuffer else {
      print("Error capturing photo: \(String(describing: error))")
      return
    }
    
    guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
      return
    }
    
    let image = UIImage.init(data: imageData, scale: 1.0)
    self.capturedImage(image: image!)
  }
  
  func enableCamera() {
    let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    
    do {
      let captureInput = try AVCaptureDeviceInput(device: captureDevice)
      
      captureSession = AVCaptureSession()
      captureSession?.addInput(captureInput)
      
      capturePhotoOutput = AVCapturePhotoOutput()
      capturePhotoOutput?.isHighResolutionCaptureEnabled = true
      
      captureSession?.addOutput(capturePhotoOutput)
      
      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
      videoPreviewLayer?.frame = previewView.layer.bounds
      previewView.layer.insertSublayer(videoPreviewLayer!, at: 0)
      
      captureSession?.startRunning()
    }
    catch {
      print(error)
    }
  }
}