//
// Copyright © 2019 Dmitry Rybakov. All rights reserved.
    

import ReplayKit
import WebRTC
import WebRTCDemoSignalling
import AwsSignalling



class WebRTCDemoBroadcastSampleHandler: RPBroadcastSampleHandler {

    var logonSuccessBool:Bool = false
    let awsClient:AwsSignallingClient  = AwsSignallingClient.init(username: "anson1788", pw: "Yu24163914!")
    var lastSendTs:Int64 = 0
    var bufferCopy:CMSampleBuffer?
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
       
        self.awsClient.setDelegate(delegate: self)
        self.awsClient.mobileLogin()
        
        DispatchQueue.main.async {
              Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {[weak self] (timer:Timer) in
                  guard let weakSelf = self else {return}
                 let elapse = Int64(Date().timeIntervalSince1970 * 1000) - self!.lastSendTs
                  // If the inter-frame interval of the video is too long, resend the previous frame.
                  if(elapse > 300) {
                 
                      if let buffer = weakSelf.bufferCopy {
                          weakSelf.processSampleBuffer(buffer, with: .video)
                      }
                    
                  }
              }
          }
    
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
      
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:

            if logonSuccessBool {
                self.bufferCopy = sampleBuffer
                self.lastSendTs = Int64(Date().timeIntervalSince1970 * 1000)
                self.awsClient.processVdo(sampleBuffer: sampleBuffer)
            }
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}

extension WebRTCDemoBroadcastSampleHandler :AwsClientDelegate {
    func logonSuccess(){
        logonSuccessBool = true
    }
}


