//
//  KVideoRecorder
//
//  Copyright © 2017 Kenan Atmaca. All rights reserved.
//  kenanatmaca.com
//
//

import UIKit
import AVFoundation

enum CaptureMode {
    case photo
    case video
}

protocol KVideoRecorderDelegate:class {
    func timer(second:Int)
}

@available(iOS 11,*)
class KVideoRecorder: NSObject {
    
    private var captureVideoDevice:AVCaptureDevice!
    private var captureAudioDevice:AVCaptureDevice!
    private var session:AVCaptureSession!
    private var previewLayer:AVCaptureVideoPreviewLayer!
    private var videoOutput:AVCaptureMovieFileOutput!
    private var photoOutput:AVCapturePhotoOutput!
    
    private var zoomGesture:UIPinchGestureRecognizer!
    private var focusGesture:UITapGestureRecognizer!
    private var toggleGesture:UITapGestureRecognizer!
    private var rootView:UIView!
    private var stateZoomScale:CGFloat = 1.0
    private var videoTimer:Timer!
    private var recordTime:Int = 0
    private var captureTyp:CaptureMode!
    
    var isAuth:Bool! {
        get {
       return auth()
        }
    }
    
    var isFocus:Bool = false
    var isZoom:Bool = true
    var isToggle:Bool = true
    var videoDelegate:AVCaptureFileOutputRecordingDelegate?
    var photoDelegate:AVCapturePhotoCaptureDelegate?
    var delegate:KVideoRecorderDelegate?
    var takePhotoImage:UIImage?
    var videoOutputUrl:URL?
    
    
     init(to view:UIView) {
        super.init()
        self.rootView = view
    }
    
    func setup(_ type:CaptureMode) {
        
        guard isAuth else {
            return
        }
        
        captureTyp = type
        
        session = AVCaptureSession()
        
        captureVideoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        captureAudioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        
        do {

            try captureVideoDevice?.lockForConfiguration()
            captureVideoDevice?.focusMode = .continuousAutoFocus
            captureVideoDevice?.unlockForConfiguration()

        } catch {
            print(error.localizedDescription)
        }
        
        do {
            
            let inputVideo = try AVCaptureDeviceInput(device: captureVideoDevice)
            let inputAudio = try AVCaptureDeviceInput(device: captureAudioDevice)
            session.addInput(inputVideo)
            session.addInput(inputAudio)
            
        } catch {
            print(error.localizedDescription)
        }
        
        switch(type) {
        case .photo:
             photoOutput = AVCapturePhotoOutput()
             session.addOutput(photoOutput)
        case .video:
             videoOutput = AVCaptureMovieFileOutput()
             session.addOutput(videoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.zPosition = -1
        previewLayer.contentsGravity = kCAGravityResizeAspectFill
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.frame = rootView.layer.bounds
        rootView.layer.addSublayer(previewLayer)
        
        focusGesture = UITapGestureRecognizer(target: self, action: #selector(focusCam(_:)))
        zoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomCamera(_:)))
        toggleGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCamera))
        toggleGesture.numberOfTapsRequired = 2
        
        if isFocus {rootView.addGestureRecognizer(focusGesture)}
        if isZoom {rootView.addGestureRecognizer(zoomGesture)}
        if isToggle {rootView.addGestureRecognizer(toggleGesture)}
        
        session.startRunning()
    }
    
    func record(name:String = "movie") {
        
        guard videoOutput != nil else {
            return
        }
        
        if !videoOutput.isRecording {
         if case captureTyp = CaptureMode.video {
             let outputURL = vidURL(name: name)
             videoOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: videoDelegate ?? self as AVCaptureFileOutputRecordingDelegate)
             if delegate != nil {videoTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setTimerCount), userInfo: nil, repeats: true)}
          }
       }
    }
    
    func savePhoto(image:UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    func saveVideo(url:URL) {
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
    }
    
    @objc private func setTimerCount() {
        
        recordTime += 1
        
        if delegate != nil {
            self.delegate?.timer(second: recordTime)
        }
    }
    
    func takePhoto() {
        
        guard photoOutput != nil else {
            return
        }
    
        if case captureTyp = CaptureMode.photo {
            let settings = AVCapturePhotoSettings()
            photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecType.jpeg])], completionHandler: nil)
            photoOutput.capturePhoto(with: settings, delegate: photoDelegate ?? self as AVCapturePhotoCaptureDelegate)
        }
    }
    
    func stop() {
        
        guard videoOutput != nil else {
            return
        }
        
        if videoOutput.isRecording {
            videoOutput.stopRecording()
            videoTimer.invalidate()
        }
    }
    
    func toggleCamera(){
        
        var newCamera:AVCaptureDevice?
        
        func cameraState(_ position:AVCaptureDevice.Position) -> AVCaptureDevice? {
            
            let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],mediaType: AVMediaTypeVideo,position: AVCaptureDevice.Position.unspecified)
            
            for device in (deviceDescoverySession?.devices)! {
                if device.position == position {
                    return device
                }
            }
            
            return nil
        }
        
        session?.beginConfiguration()
        
        let currentInput = session.inputs.first as! AVCaptureInput!
        
        session.removeInput(currentInput!)
        
        if captureVideoDevice?.position == AVCaptureDevice.Position.back {
            
            newCamera = cameraState(AVCaptureDevice.Position.front)
            
        } else {
            
            newCamera = cameraState(AVCaptureDevice.Position.back)
        }
        
        captureVideoDevice = newCamera
        
        do {
            
            let deviceInput = try AVCaptureDeviceInput(device: newCamera!)
            
            session?.addInput(deviceInput)
            
        } catch {
           print(error.localizedDescription)
        }
        
        session?.commitConfiguration()
    }
    
    @objc private func focusCam(_ sender:UITapGestureRecognizer) {
        
        let point = sender.location(in: rootView)
        focusObject(point)
    }
    
    private func focusObject(_ point:CGPoint){
        
        if let device = captureVideoDevice {
            
            do {
                
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported {
                    
                    device.focusPointOfInterest = point
                }
                
                if device.isExposurePointOfInterestSupported {
                    
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc private func zoomCamera(_ sender:UIPinchGestureRecognizer){
        
        if let device = captureVideoDevice {
            
            if sender.state == UIGestureRecognizerState.began { sender.scale = stateZoomScale }
            
            if sender.state == UIGestureRecognizerState.ended { stateZoomScale = device.videoZoomFactor }
            
            if sender.scale <= 1 { sender.scale = 1 }
                
            else if sender.scale >= 4 { sender.scale = 4 }
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = sender.scale
                device.unlockForConfiguration()
            } catch  {
                print(error.localizedDescription)
            }
        }
    }
    
     private func getDir() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths.first!
    }
    
    private func auth() -> Bool {
            
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            
        switch (status) {
        case .authorized: return true
        case .denied,.notDetermined,.restricted : return false
        }
    }
    
    func isExist(name:String) -> Bool {
        
        let bundle = getDir().appendingPathComponent(name.appending(".mov"))
        let manager = FileManager.default
        
        return manager.fileExists(atPath: bundle.path) ? true : false
    }
    
    @discardableResult
    func delete(name:String) -> Bool {
        
        let bundle = getDir().appendingPathComponent(name.appending(".mov"))
        let manager = FileManager.default
        var result:Bool = false
        
        if self.isExist(name: name) {
            do {
                try manager.removeItem(at: bundle)
                result = true
            } catch {
                print(error.localizedDescription)
                result = false
            }
        }
        
        return result
    }
    
    func removeView() {
        if videoTimer != nil {videoTimer.invalidate()}
        session = nil
        videoOutputUrl = nil
        takePhotoImage = nil
        recordTime = 0
        previewLayer.removeFromSuperlayer()
    }
    
    func vidURL(name:String) -> URL {
        return getDir().appendingPathComponent(name.appending(".mov"))
    }
    
}//

@available(iOS 11,*)
extension KVideoRecorder: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imgData = photo.fileDataRepresentation() {
            takePhotoImage = UIImage(data: imgData)
        }
    }
}

@available(iOS 11,*)
extension KVideoRecorder: AVCaptureFileOutputRecordingDelegate {
    func capture(_ output: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {}
    func capture(_ output: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
       
        if error != nil {
            return
        }
        
        self.videoOutputUrl = outputFileURL
    }
}

