//
//  ViewController.swift
//  RealTimeFaceDetection
//
//  Created by Mert Tuzer on 16.08.2019.
//  Copyright © 2019 Mert Tuzer. All rights reserved.
//

import UIKit
import Vision
import AVKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var cameraLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAVLayerandSession()
        
    }
    
    func setupAVLayerandSession() {
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video capturer!")
            return
        }
        
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        view.layer.addSublayer(cameraLayer)
        cameraLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue") )


        captureSession.addOutput(dataOutput)
        
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        
        let faceRequest = VNDetectFaceRectanglesRequest { (request, requestError) in
            if let error = requestError {
                print("We have a request error: ", error)
                return
            }
            
            
            request.results?.forEach({ (result) in
                guard let faceBoxes = result as? VNFaceObservation else { return }
                
                DispatchQueue.main.async {
                    if let oldView = self.view.viewWithTag(2) {
                        oldView.removeFromSuperview()
                        print("removed")
                    }
                    else {
                        print("not removed")
                    }
                    let height =  self.view.frame.height * faceBoxes.boundingBox.height
                    let x = self.view.frame.width * faceBoxes.boundingBox.origin.x
                    let y = self.cameraLayer.frame.height * (1 - faceBoxes.boundingBox.height) - height
                    let width = self.view.frame.width * faceBoxes.boundingBox.width
                    
                    
                    let boxView = UIView()
                    boxView.backgroundColor = .red
                    boxView.alpha = 0.3
                    boxView.tag = 2
                    boxView.frame = CGRect(x: x, y: y, width: width, height: height)
                    print(boxView.frame)
                    
                    self.view.addSubview(boxView)
                    
                    
                }
                
            })
            
        }
        
        
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([faceRequest])
        } catch let handlerError {
            print("A handle occurred with the description: ", handlerError)
        }
        
        
    }


}

