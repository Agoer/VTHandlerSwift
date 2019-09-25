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
    
    lazy var fileOutput = AVCaptureMovieFileOutput()
    
    var videoConnection:AVCaptureConnection?
    
    var videoPreviewLayer:AVCaptureVideoPreviewLayer = {
       let videoPreviewLayer = AVCaptureVideoPreviewLayer()
        return videoPreviewLayer
    }()
    
    var recordEncoder:AGRecordEncoder!
    var recordEngineStatus = AGRecordEngineStatus()
    
    func getUploadFile(type:String, fileType:AVFileType) -> String {
        let now = NSDate().timeIntervalSince1970
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        let nowDate = Date(timeIntervalSince1970: now)
        let timeStr = formatter.string(from: nowDate)
        var suffexStr = "mp4"
        if fileType == .mp3 {
            suffexStr = "mp3"
        }
        let fileName = "\(type)_\(timeStr).\(suffexStr)"
        return fileName
    }
    
    class func getMediaCachePath() -> String {
        let fileUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("videos")
        let mediaCache = fileUrl.path
        guard !FileManager.default.fileExists(atPath: mediaCache) else {
            return mediaCache
        }
        try! FileManager.default.createDirectory(atPath: mediaCache, withIntermediateDirectories: true, attributes: nil)
        return mediaCache
    }

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
//        self.videoOutput.videoSettings = kVideoSettings
//        let videoOutputQueue = DispatchQueue(label: "ACVideoCaptureOutputQueue", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)
//        self.videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
//
//        // audioOutput config
//        let audioOutputQueue = DispatchQueue(label: "ACAudioCaptureOutputQueue", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)
//        self.audioOutput.setSampleBufferDelegate(self, queue: audioOutputQueue)

        self.sesstion.addOutput(self.fileOutput)
        
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
        
        //  设置录像保存地址，在 Documents 目录下，名为 当前时间.mp4
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory = path[0] as String
        let filePath: String? = "\(documentDirectory)/\(Date()).mp4"
        let fileUrl: URL? = URL(fileURLWithPath: filePath!)
        //  启动视频编码输出
        self.fileOutput.startRecording(to: fileUrl!, recordingDelegate: self)
        
        return true
    }
    
    @objc func stopRecord() -> Bool {
        
        guard isRecording else {
            return false
        }
        
        self.sesstion.stopRunning()
        self.isRecording = false
//        self.recordEncoder.writer.finishWriting {
//            
//        }
        return true
    }
    
    func adjustTime(sample:CMSampleBuffer, offset:CMTime) -> CMSampleBuffer {
        var count:CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)
        let pInfo:UnsafeMutablePointer<CMSampleTimingInfo> = UnsafeMutablePointer.allocate(capacity: (MemoryLayout.size(ofValue: sample) * count))
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: count, arrayToFill: pInfo, entriesNeededOut: &count)
        var sout:CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sample, sampleTimingEntryCount: count, sampleTimingArray: pInfo, sampleBufferOut: &sout)
        return sout!
//        return sout.pointee
    }
    
}

extension BothRecordController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    // out video & audio
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if self.recordEncoder == nil {
            do {
                let cachePath = BothRecordController.getMediaCachePath()
                let mediaPath = self.getUploadFile(type: "video", fileType: .mp4)
                let path = URL(fileURLWithPath: cachePath, isDirectory: true).appendingPathComponent(mediaPath).path
                self.recordEncoder = try AGRecordEncoder(mediaPath: path)
            } catch {
                return
            }
            
        }
        var type:AVMediaType = .video
        if(output == self.videoOutput) {
            //视频编码
            if(self.recordEncoder.videoStreamDesc == nil) {
                let videoStreamDesc = AGVideoStreamDesc(videoWidth: 720, videoHeight: 1280, videoPath: nil)
                self.recordEncoder.videoStreamDesc = videoStreamDesc
            }
            type = .video
            print(">>>video")
        }
        if(output == self.audioOutput) {
            //音频编码
            if(self.recordEncoder.audioStreamDesc == nil) {
                let fmt = CMSampleBufferGetFormatDescription(sampleBuffer)!
                let audioStreamDesc = AGAudioStreamDesc(audioPath: nil, fmt: fmt)
                self.recordEncoder.audioStreamDesc = audioStreamDesc
            }
            type = .audio
            print(">>>audio")
        }
        
        objc_sync_enter(self)

        if self.recordEngineStatus.hadSuspend {
            self.recordEngineStatus.hadSuspend = false
            var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let lastTime = type == .video ? recordEngineStatus.lastVideoTime:recordEngineStatus.lastAudioTime
            if (lastTime.isValid) {
                let offsetTime = self.recordEngineStatus.offsetTime
                if(offsetTime.isValid) {
                    pts = CMTimeSubtract(pts, offsetTime)
                }
                let tempOffset = CMTimeSubtract(pts, lastTime)
                self.recordEngineStatus.offsetTime = CMTimeAdd(offsetTime, tempOffset)
            }
            self.recordEngineStatus.lastVideoTime.flags = CMTimeFlags.valid
            self.recordEngineStatus.lastAudioTime.flags = CMTimeFlags.valid
        }
        
        let offsetTime = self.recordEngineStatus.offsetTime
        var nSampleBuffer = sampleBuffer
        if offsetTime.value > 0 {
            nSampleBuffer = self.adjustTime(sample: sampleBuffer, offset: offsetTime)
        }
        var pts = CMSampleBufferGetPresentationTimeStamp(nSampleBuffer)
        let dur = CMSampleBufferGetDuration(nSampleBuffer)
        if dur.value > 0 {
            pts = CMTimeAdd(pts, dur)
        }
        switch type {
        case .video:
            self.recordEngineStatus.lastAudioTime = pts
        case .audio:
            self.recordEngineStatus.lastAudioTime = pts
        default:
            break
        }
        
        objc_sync_exit(self)
        
        let nDur = CMSampleBufferGetPresentationTimeStamp(nSampleBuffer)
        if self.recordEngineStatus.startTime.value == 0 {
            self.recordEngineStatus.startTime = nDur
        }
        let startTime = self.recordEngineStatus.startTime
        let nSub = CMTimeSubtract(dur, startTime)
        self.recordEngineStatus.currentRecordTime = CMTimeGetSeconds(nSub)
        
        guard self.recordEngineStatus.currentRecordTime <= self.recordEngineStatus.maxRecordTime else {
            if self.recordEngineStatus.currentRecordTime - self.recordEngineStatus.maxRecordTime < 0.1 {
                //todo
                print("时间溢出")
            }
            return
        }
        
        //todoSam
       let result = self.recordEncoder.encodeFrame(sampleBuffer: nSampleBuffer, type: type)
        print(result)
    }
    
    // drop
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    
}

extension BothRecordController: AVCaptureFileOutputRecordingDelegate {
    /// 开始录制
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
    }
    
    /// 结束录制
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(outputFileURL)
    }
}

