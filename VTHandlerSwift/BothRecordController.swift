//
//  BothRecordController.swift
//  VTHandlerSwift
//
//  Created by yixin on 2019/8/21.
//  Copyright © 2019 IUTeam. All rights reserved.
//

import UIKit
import AVFoundation

//设置视频分辨率
let kVideoPreset = AVCaptureSession.Preset.hd1280x720

//YUV420 格式返回
let kVideoSettings:[String:Any] = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]

class BothRecordController: UIViewController {
    
    //采集管理类
    lazy var sesstion:AVCaptureSession = {
        let sesstion = AVCaptureSession()
        return sesstion
    }()
    
    //设置 video input 对象
    lazy var videoInput:AVCaptureDeviceInput? = {
        //默认为前置摄像头
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            return videoInput
        } catch {
            print("videoInput init failed~")
            return nil
        }
    }()
    
    //设置 audio input 对象
    lazy var audioInput:AVCaptureDeviceInput? = {
        //默认为前置摄像头
        let device = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)!
        do {
            let audioInput = try AVCaptureDeviceInput(device: device)
            return audioInput
        } catch {
            print("audioInput init failed~")
            return nil
        }
    }()
    
    //set AVCaptureVideoDataOutput obj.
    lazy var videoOutput:AVCaptureVideoDataOutput = {
       let videoOutput = AVCaptureVideoDataOutput()
        return videoOutput
    }()
    
    lazy var audioOutput:AVCaptureAudioDataOutput = {
       let audioOutput = AVCaptureAudioDataOutput()
        return audioOutput
    }()
    
    var videoConnection:AVCaptureConnection?
    
    var videoPreviewLayer:AVCaptureVideoPreviewLayer = {
       let videoPreviewLayer = AVCaptureVideoPreviewLayer()
        return videoPreviewLayer
    }()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        // 关联绑定
        self.binding()
        // Do any additional setup after loading the view.
    }
    
    private func binding() {
        
        //session config
        //在 iOS7 之前,AVCaptureSession 使用它自己的音频会话,这可能会在与应用程序的音频会话交互时导致不必要的中断.
        self.sesstion.usesApplicationAudioSession = false
        if(self.sesstion.canSetSessionPreset(kVideoPreset)) {
            self.sesstion.sessionPreset = kVideoPreset
        }
        
        // videoOutput config
        self.videoOutput.videoSettings = kVideoSettings
        let videoOutputQueue = DispatchQueue(label: "ACVideoCaptureOutputQueue", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        self.videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        
        // audioOutput config
        let audioOutputQueue = DispatchQueue(label: "ACAudioCaptureOutputQueue", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        self.audioOutput.setSampleBufferDelegate(self, queue: audioOutputQueue)
        
        
        //videoInput、Output bind to sesstion
        guard (self.videoInput != nil) && self.sesstion.canAddInput(self.videoInput!) else {
            print("addInput videoInput failed.")
            return;
        }
        self.sesstion.addInput(self.videoInput!)
        
        guard (self.audioInput != nil) && self.sesstion.canAddInput(self.audioInput!) else {
            print("addInput audioInput failed.")
            return;
        }
        self.sesstion.addInput(self.audioInput!)
        
        
        guard self.sesstion.canAddOutput(self.videoOutput) else {
            print("addOutput videoOutput failed.")
            return;
        }
        self.sesstion.addOutput(self.videoOutput)
        
        guard self.sesstion.canAddOutput(self.audioOutput) else {
            print("addOutput audioOutput failed.")
            return;
        }
        self.sesstion.addOutput(self.audioOutput)
        
        //video conn
         self.videoConnection = self.videoOutput.connection(with: .video)
        guard self.videoConnection != nil else {
            print("videoConnection init failed.")
            return;
        }
        self.videoConnection!.videoOrientation = .portrait
        if(self.audioInput?.device.position == .front && self.videoConnection!.isVideoMirroringSupported) {
            self.videoConnection?.isVideoMirrored = true
        }
        
        // Previewer
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.sesstion)
        self.videoPreviewLayer.connection?.videoOrientation = .portrait
        self.videoPreviewLayer.videoGravity = .resizeAspectFill
        self.view.layer.insertSublayer(self.videoPreviewLayer, at: 0)
        self.videoPreviewLayer.frame = self.view.layer.bounds
        
        
        let startButton = UIButton(frame: CGRect(x: 10, y: 100, width: 100, height: 40))
        startButton.setTitle("开始", for: .normal)
        startButton.setTitleColor(UIColor.red, for: .normal)
        self.view.addSubview(startButton)
        
        startButton.addTarget(self, action: #selector(startRecord), for: .touchUpInside)
        
        let stopButton = UIButton(frame: CGRect(x: 10, y: 150, width: 100, height: 40))
        stopButton.setTitle("停止", for: .normal)
        stopButton.setTitleColor(UIColor.red, for: .normal)
        self.view.addSubview(stopButton)
        
        stopButton.addTarget(self, action: #selector(stopRecord), for: .touchUpInside)
        
    }
    
    
    var isRecording:Bool = false
    
    @objc func startRecord() -> Bool {
        
        guard !isRecording else {
            return false
        }
        
        let videoAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard videoAuthStatus == .authorized else {
            return false
        }
        
        let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        guard audioAuthStatus == .authorized else {
            return false
        }
        
        self.sesstion.startRunning()
        self.isRecording = true
        return true
    }
    
    @objc func stopRecord() -> Bool {
        
        guard isRecording else {
            return false
        }
        
        self.sesstion.stopRunning()
        self.isRecording = false
        return true
    }
    
}

extension BothRecordController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    // out video & audio
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("didOutput")
    }
    
    // drop
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    
}

