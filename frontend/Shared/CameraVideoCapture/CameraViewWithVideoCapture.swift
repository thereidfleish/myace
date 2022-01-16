//
//  CameraViewWithVideoCapture.swift
//  AI Tennis Coach (iOS)
//
//  Created by AndrewC on 1/13/22.
//

import SwiftUI
import AVFoundation
import Photos

struct CamPreviewView: UIViewRepresentable {
    @ObservedObject var camera : CameraCapture
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.previewLayer = AVCaptureVideoPreviewLayer(session: camera.captureSession)
        camera.previewLayer.frame = view.frame
        
        // Your Own Properties...
        camera.previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.previewLayer)
        
        // starting session
        //camera.startSession()
        camera.viewDidLoad()
        
        return view
        //return CameraCapture.instance.camPreview
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

struct VideoPlaybackView: UIViewRepresentable {
    @ObservedObject var vp : VideoPlayback
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        vp.viewDidLoad()
        view.layer.addSublayer(vp.avPlayerLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

class VideoPlayback: UIViewController, ObservableObject {
    static var instance : VideoPlayback?
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!

    var videoURL: URL?
    //connect this to your uiview in storyboard
    // @IBOutlet weak var videoView: UIView!

    static func getInstance() -> VideoPlayback {
        if let safeInstance = instance {
            return safeInstance
        }
        else {
            instance = VideoPlayback()
            return instance!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("helloooooooo")
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // videoView.layer.insertSublayer(avPlayerLayer, at: 0)
    
        view.layoutIfNeeded()
        guard let videoURLSafe = videoURL else {
            return
        }
        let playerItem = AVPlayerItem(url: videoURLSafe as URL)
        avPlayer.replaceCurrentItem(with: playerItem)
    
        avPlayer.play()
    }
}

class CameraCapture: UIViewController, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    //static var instance = CameraCapture()
        //@IBOutlet weak var camPreview: UIView!

        //let cameraButton = UIView()

    @Published var captureSession = AVCaptureSession()

    @Published var movieOutput = AVCaptureMovieFileOutput()

    @Published var previewLayer: AVCaptureVideoPreviewLayer!

    @Published var activeInput: AVCaptureDeviceInput!

    @Published var outputURL: URL!

    override func viewDidLoad() {
        super.viewDidLoad()
        if setupSession() {
            //setupPreview()
            startSession()
        }

    }

    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        //previewLayer.frame = camPreview.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        //camPreview.layer.addSublayer(previewLayer)
    }

    //MARK:- Setup Camera

    func setupSession() -> Bool {
    
        captureSession.sessionPreset = AVCaptureSession.Preset.high
    
        // Setup Camera
        let camera = AVCaptureDevice.default(for: AVMediaType.video)!
    
        do {
        
            let input = try AVCaptureDeviceInput(device: camera)
        
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
    
        // Setup Microphone
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
    
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
    
    
        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
    
        return true
    }

    func setupCaptureMode(_ mode: Int) {
        // Video Mode
    
    }

    //MARK:- Camera Session
    func startSession() {
    
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }

    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }

    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }

    func currentVideoOrientation() -> AVCaptureVideoOrientation {
//            var orientation: AVCaptureVideoOrientation
//
//            switch UIDevice.current.orientation {
//                case .portrait:
//                    orientation = AVCaptureVideoOrientation.portrait
//                case .landscapeRight:
//                    orientation = AVCaptureVideoOrientation.landscapeLeft
//                case .portraitUpsideDown:
//                    orientation = AVCaptureVideoOrientation.portraitUpsideDown
//                default:
//                     orientation = AVCaptureVideoOrientation.landscapeRight
//             }
//
//             return orientation
        return AVCaptureVideoOrientation.portrait
     }

    @objc func startCapture() {
    
        startRecording()
    
    }

    

    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
    
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
    
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! VideoPlayback
        vc.videoURL = sender as! URL
    }

    func startRecording() {
    
        if movieOutput.isRecording == false {
        
            let connection = movieOutput.connection(with: AVMediaType.video)
        
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }
        
            // Note from Andrew: I removed a some of this stablilization/auto focus feature because it was causing the videos to lag at the very beginning of recording. Keeping it in case we can figure out a work around.
            /*
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
        
            let device = activeInput.device
        
            if (device.isSmoothAutoFocusSupported) {
            
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                   print("Error setting configuration: \(error)")
                }
            
            }
        */
 
            outputURL = tempURL()
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        }
        else {
            stopRecording()
        }
    
    }

   func stopRecording() {
    
       if movieOutput.isRecording == true {
           movieOutput.stopRecording()
        }
   }

    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
    
    }
    

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    
        if (error != nil) {
        
            print("Error recording movie: \(error!.localizedDescription)")
        
        } else {
        
            let videoRecorded = outputURL! as URL
            print(videoRecorded)
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoRecorded)
            })
            //performSegue(withIdentifier: "showVideo", sender: videoRecorded)
            
            // Will work on video playback later. Leaving the code here for now.
            //VideoPlayback.getInstance().videoURL = videoRecorded
            
        }
    
    }
}
