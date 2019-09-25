//
//  AGRecordEncoder.swift
//  VTHandlerSwift
//
//  Created by yixin on 2019/9/6.
//  Copyright © 2019 IUTeam. All rights reserved.
//

import Foundation
import AVFoundation

enum AGRecordEncoderError:Error {
    case videoAndAudioDescBeNil
}

struct AGVideoStreamDesc {
    var videoWidth:Float
    var videoHeight:Float
    var videoPath:String?
}

struct AGAudioStreamDesc {
    var mSampleRate:Float64
    var mChannelsPerFrame:UInt32
    var mBitRateKey:Int = 12800
    init(audioPath:String?,fmt:CMFormatDescription) {
        let asbd:UnsafePointer<AudioStreamBasicDescription> = CMAudioFormatDescriptionGetStreamBasicDescription(fmt)!
        mSampleRate = asbd.pointee.mSampleRate
        mChannelsPerFrame = asbd.pointee.mChannelsPerFrame
    }
}

class AGRecordEncoder {
    private var mediaPath:String!
    private var mediaFileType:AVFileType = .mp4
    var writer:AVAssetWriter!
    var recordPath:String!
    var videoStreamDesc:AGVideoStreamDesc! {
        didSet {
            guard videoStreamDesc != nil else {
                return
            }
            guard videoWriterInput != nil else {
                //初始化视频输入
                let settings:[String : Any] = [AVVideoCodecKey:AVVideoCodecH264,AVVideoWidthKey:NSNumber(value: videoStreamDesc.videoWidth),AVVideoHeightKey:NSNumber(value: videoStreamDesc.videoHeight)]
                videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
                //表明输入是否应该调整其处理为实时数据源的数据
                videoWriterInput.expectsMediaDataInRealTime = true
                writer.add(videoWriterInput)
                return
            }
        }
    }
    var videoWriterInput:AVAssetWriterInput!
    var audioStreamDesc:AGAudioStreamDesc! {
        didSet {
            guard audioStreamDesc != nil else {
                return
            }
            guard audioWriterInput != nil else {
                //初始化视频输入
                let settings:[String : Any] = [AVFormatIDKey:NSNumber(value: kAudioFormatMPEG4AAC),AVNumberOfChannelsKey:NSNumber(value: audioStreamDesc.mChannelsPerFrame),AVSampleRateKey:NSNumber(value: audioStreamDesc.mSampleRate)]
                audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
                //表明输入是否应该调整其处理为实时数据源的数据
                audioWriterInput.expectsMediaDataInRealTime = true
                writer.add(audioWriterInput)
                return
            }
            
        }
    }
    var audioWriterInput:AVAssetWriterInput!
    
    
    init(mediaPath:String!, mediaFileType:AVFileType = .mp4, _ videoDesc:AGVideoStreamDesc? = nil, _ audioDesc:AGAudioStreamDesc? = nil) throws {
        try? FileManager.default.removeItem(atPath: mediaPath)
        let url = URL(fileURLWithPath: mediaPath)
        writer = try! AVAssetWriter(url: url, fileType: mediaFileType)
        writer.shouldOptimizeForNetworkUse = true
        
        self.videoStreamDesc = videoDesc
        self.audioStreamDesc = audioDesc
    }
    
    @discardableResult
    func encodeFrame(sampleBuffer:CMSampleBuffer, type:AVMediaType) -> Bool {
        
        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            return false
        }
        if(writer.status == .unknown) {
            let startTime:CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            writer.startWriting()
            writer.startSession(atSourceTime: startTime)
        }
        if writer.status == .failed {
            return false
        }
        switch type {
        case .video:
            if videoWriterInput.isReadyForMoreMediaData {
                videoWriterInput.append(sampleBuffer)
                return true
            }
        default:
            if audioWriterInput.isReadyForMoreMediaData {
                audioWriterInput.append(sampleBuffer)
                return true
            }
        }
        return false
    }
}
