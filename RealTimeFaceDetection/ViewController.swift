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
    
    fileprivate var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create the video feed
        createAVsession()
    }
    
    fileprivate func createAVsession() {
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video capturer!")
            return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        let cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraLayer)
        cameraLayer.frame = view.frame
        
        captureSession.startRunning()
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue") )
        captureSession.addOutput(dataOutput)
        
        guard let connection = dataOutput.connection(with: AVFoundation.AVMediaType.video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait

    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // try to get pixelbuffer 'images'
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // let's make a request for the rectangle covering the face
        let faceRequest = VNDetectFaceRectanglesRequest { [unowned self] (request, requestError) in
            // control whether an error occurs
            if let error = requestError {
                print("We have a request error: ", error)
                return
            }
            
            DispatchQueue.main.async {
                // remove face rectangles from the previous frame if exists
                for i in 100..<self.count+100 {
                    if let oldView = self.view.viewWithTag(i) {
                        oldView.removeFromSuperview()
                    }
                }
                // check to get face rectangle results
                guard let requestResults = request.results else { return }
                
                // counter is for tagging rectangles so that they can be removed
                var counter = 100
                self.count = requestResults.count
                
                // iterate rectangle results to process
                requestResults.forEach({ (result) in
                    
                    guard let faceBoxes = result as? VNFaceObservation else { return }
                    
                    // construct the rectangle from the normalized boundingBox values.
                    let x = self.view.frame.width * faceBoxes.boundingBox.origin.x
                    let height = self.view.frame.height * faceBoxes.boundingBox.height
                    let width = self.view.frame.width * faceBoxes.boundingBox.width
                    let y = self.view.frame.height - height - self.view.frame.height * faceBoxes.boundingBox.origin.y
                
                    // create the box to be drawn on self.view
                    self.createBox(x, y, width, height, counter)
                    counter += 1
                })
            }
        }
        
        // let's handle the request
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([faceRequest])
        } catch let handlerError {
            print("A handle occurred with the description: ", handlerError)
        }
    }

    fileprivate func createBox(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ counter: Int) {
        let boxView = UIView()
        boxView.backgroundColor = .red
        boxView.alpha = 0.4
        boxView.tag = counter
        boxView.frame = CGRect(x: x, y: y, width: width, height: height)
        self.view.addSubview(boxView)
    }
    
}

