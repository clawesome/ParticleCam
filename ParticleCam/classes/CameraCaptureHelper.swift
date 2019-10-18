//
//  CameraCaptureHelper.swift
//  ParticleCam
//
//  Created by Simon Gladman on 12/02/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//


import AVFoundation
import CoreMedia
import CoreImage
import UIKit

/// `CameraCaptureHelper` wraps up all the code required to access an iOS device's
/// camera images and convert to a series of `CIImage` images.
///
/// The helper's delegate, `CameraCaptureHelperDelegate` receives notification of
/// a new image in the main thread via `newCameraImage()`.
class CameraCaptureHelper: NSObject {
    let captureSession = AVCaptureSession()
    let cameraPosition: AVCaptureDevice.Position
    
    weak var delegate: CameraCaptureHelperDelegate?
    private var videoDataOutputQueue: DispatchQueue?
    
    required init(cameraPosition: AVCaptureDevice.Position) {
        self.cameraPosition = cameraPosition
        
        super.init()
        
        initialiseCaptureSession()
    }
    
    private func initialiseCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        guard let camera = (AVCaptureDevice.devices(for: AVMediaType.video))
            .filter({ $0.position == cameraPosition })
            .first else {
            fatalError("Unable to access camera")
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            captureSession.addInput(input)
        } catch {
            fatalError("Unable to access back camera")
        }
        
        
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoDataOutputQueue = DispatchQueue(label: "sample buffer delegate")
        videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        //videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.startRunning()
    }
}

extension CameraCaptureHelper: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        DispatchQueue.main.sync {
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
            self.delegate?.newCameraImage(cameraCaptureHelper: self,
                                          image: CIImage(cvPixelBuffer: pixelBuffer))
        }
        
    }
}

protocol CameraCaptureHelperDelegate: class {
    func newCameraImage(cameraCaptureHelper: CameraCaptureHelper, image: CIImage)
}
