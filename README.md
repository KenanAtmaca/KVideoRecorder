# KVideoRecorder
iOS 11 Record Video &amp; Take Photo Helper Class 📹

#### Use

```Swift
        recorder = KVideoRecorder(to: self.view)
        recorder.setup(.video) // .video , .photo
```

##### Delegate

```Swift
     extension mainVC: KVideoRecorderDelegate {
         func timer(second: Int) {
        // video second
        }
      }
```

##### Usable Functions

```Swift
        recorder.record(name:)
        recorder.takePhoto()
        recorder.savePhoto(image:)
        recorder.saveVideo(url:)
        recorder.toggleCamera()
        recorder.isExist(name:)
        recorder.delete(name:)
        recorder.vidURL(name:)
```

##### Usable Veriables

```Swift
        recorder.isAuth:Bool
        recorder.isFocus:Bool
        recorder.isZoom:Bool
        recorder.isToggle:Bool
        recorder.videoDelegate:AVCaptureFileOutputRecordingDelegate
        recorder.photoDelegate:AVCapturePhotoCaptureDelegate
        recorder.delegate:KVideoRecorderDelegate      
        recorder.takePhotoImage:UIImage
        recorder.videoOutputUrl:URL
```


## License
Usage is provided under the [MIT License](http://http//opensource.org/licenses/mit-license.php). See LICENSE for the full details.
