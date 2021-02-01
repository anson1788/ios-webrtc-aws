//
//  AwsClient.swift
//  WebRTCDemoSignalling
//
//  Created by ANSON on 29/1/2021.
//  Copyright © 2021 demo. All rights reserved.
//

import Foundation
import AWSMobileClient
import AWSCognitoIdentityProvider
import AWSKinesisVideo
import AWSKinesisVideoSignaling
import WebRTC

public class AwsSignallingClient {
    	
    var delegate:AwsClientDelegate?
    let username, pw :String
    var channelARN: String?
    var AWSCredentials: AWSCredentials?
    var wssURL: URL?
    var webRTCClient: WebRTCClient?
    lazy var localSenderId: String = {
        return connectAsViewClientId
    }()
    var signalingClient: SignalingClient?

    var iceServerList: [AWSKinesisVideoSignalingIceServer]?
    
    var awsRegionType: AWSRegionType = .Unknown
    
    var signalingConnected: Bool = false
    var remoteSenderClientId: String?
    
    public init(username: String,pw :String) {
           self.username   = username
           self.pw = pw
    }
    

    public func setDelegate(delegate:AwsClientDelegate){
        self.delegate = delegate
    }
    public func testCall(){
        self.delegate?.logonSuccess()
    }
    
    public func didCaptureVideoFrameFront(){
        self.webRTCClient?.didCaptureVideoFrameFront()
    }
    
    public func processVdo(sampleBuffer: CMSampleBuffer){
        self.webRTCClient?.sendVDO(sampleBuffer: sampleBuffer)
    }
    public func didCaptureVideoFrame(videoFrame:RTCVideoFrame){
        self.webRTCClient?.didCaptureVideoFrame(videoFrame: videoFrame)
    }
    public func initAwsConfig(sucessCallBack:((UserState)->(Void))?,errorCallBack:( ()->(Void))?){
        AWSDDLog.sharedInstance.logLevel = .verbose
        let serviceConfiguration = AWSServiceConfiguration(region: cognitoIdentityUserPoolRegion, credentialsProvider: nil)
        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: cognitoIdentityUserPoolAppClientId,
                                                                        clientSecret: cognitoIdentityUserPoolAppClientSecret,
                                                                        poolId: cognitoIdentityUserPoolId)
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: poolConfiguration, forKey: awsCognitoUserPoolsSignInProviderKey)

        AWSMobileClient.default().initialize { (userState, error) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                errorCallBack?()
                return
            }
            guard let userState = userState else {
                errorCallBack?()
                return
            }
            print("The user is \(userState.rawValue).")
            sucessCallBack?(userState)
        }
    }
    public func mobileLogin(){
        initAwsConfig(sucessCallBack: {(userState) in

            switch(userState){
                case .signedIn:
                    print("signIn Success")
                    self.connectAsViewer()
                case .signedOut:
                    print("perform signIn")
                    AWSMobileClient.default().signIn(username: self.username, password: self.pw) { (signInResult, error) in

                        DispatchQueue.main.async {
                            if let error = error {
                                print("signInError")
                            } else if let signInResult = signInResult {
                                switch (signInResult.signInState) {
                                case .signedIn:
                                    print("signIn Success")
                                    self.connectAsViewer()
                                default:
                                    print("signInError")
                                }
                            }
                        }
                        
                    }
                default:
                    print("signInError")
            }
        }, errorCallBack: {() in
            
        })
        
    }
    
    public func connectAsViewer(){
        connectAsRole(role: viewerRole, connectAsUser: (connectAsViewerKey))
    }
    
    func connectAsRole(role: String, connectAsUser: String) {
        let channelNameValue:String = "IosClientTest"
        let awsRegionValue:String = "ap-east-1"
        var awsRegionType: AWSRegionType = .Unknown
        self.awsRegionType = awsRegionValue.aws_regionTypeValue()
        let configuration = AWSServiceConfiguration(region:  self.awsRegionType, credentialsProvider: AWSMobileClient.default())
        AWSKinesisVideo.register(with: configuration!, forKey: awsKinesisVideoKey)
        retrieveChannelARN(channelName: channelNameValue)
        print("The user is \(self.channelARN).")
        retrieveChannelARN(channelName: channelNameValue)
        if self.channelARN == nil {
            print("no channel")
        }
        getSignedWSSUrl(channelARN: self.channelARN!, role: role, connectAs: connectAsUser, region: awsRegionValue)
        print("WSS URL :", wssURL?.absoluteString as Any)
        var RTCIceServersList = [RTCIceServer]()
        
        for iceServers in self.iceServerList! {
            RTCIceServersList.append(RTCIceServer.init(urlStrings: iceServers.uris!, username: iceServers.username, credential: iceServers.password))
        }
        RTCIceServersList.append(RTCIceServer.init(urlStrings: ["stun:stun.kinesisvideo." + awsRegionValue + ".amazonaws.com:443"]))
        webRTCClient = WebRTCClient(iceServers: RTCIceServersList, isAudioOn: false)
        webRTCClient!.delegate = self
        
        print("Connecting to web socket from channel config")
        signalingClient = SignalingClient(serverUrl: wssURL!)
        signalingClient!.delegate = self
        signalingClient!.connect()

        let seconds = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.webRTCClient?.offer { sdp in
                self.signalingClient?.sendOffer(rtcSdp: sdp, senderClientid: self.localSenderId)
            }
            if self.signalingConnected {
                print("connect")
                self.delegate?.logonSuccess()
            }else{
                print("not connect")
            }
        }
    }
    
    func retrieveChannelARN(channelName: String) {
        if !channelName.isEmpty {
            let describeInput = AWSKinesisVideoDescribeSignalingChannelInput()
            describeInput?.channelName = channelName
            let kvsClient = AWSKinesisVideo(forKey: awsKinesisVideoKey)
            kvsClient.describeSignalingChannel(describeInput!).continueWith(block: { (task) -> Void in
                if let error = task.error {
                    print("Error describing channel: \(error)")
                } else {
                    self.channelARN = task.result?.channelInfo?.channelARN
                    print("Channel ARN : ", task.result!.channelInfo!.channelARN ?? "Channel ARN empty.")
                }
            }).waitUntilFinished()
        } else {
            print("no cannel")
            return
        }
    }
    
    func getSignedWSSUrl(channelARN: String, role: String, connectAs: String, region: String) {
        let singleMasterChannelEndpointConfiguration = AWSKinesisVideoSingleMasterChannelEndpointConfiguration()
        singleMasterChannelEndpointConfiguration?.protocols = videoProtocols
        singleMasterChannelEndpointConfiguration?.role = getSingleMasterChannelEndpointRole()
    
        var httpResourceEndpointItem = AWSKinesisVideoResourceEndpointListItem()
        var wssResourceEndpointItem = AWSKinesisVideoResourceEndpointListItem()
        let kvsClient = AWSKinesisVideo(forKey: awsKinesisVideoKey)
        
        let signalingEndpointInput = AWSKinesisVideoGetSignalingChannelEndpointInput()
        signalingEndpointInput?.channelARN = channelARN
        signalingEndpointInput?.singleMasterChannelEndpointConfiguration = singleMasterChannelEndpointConfiguration
        
        kvsClient.getSignalingChannelEndpoint(signalingEndpointInput!).continueWith(block: { (task) -> Void in
            if let error = task.error {
                print("Error to get channel endpoint: \(error)")
            } else {
                print("Resource Endpoint List : ", task.result!.resourceEndpointList!)
            }
            guard (task.result?.resourceEndpointList) != nil else {
               print("Invalid Region Field")
                return
            }
            
            for endpoint in task.result!.resourceEndpointList! {
                switch endpoint.protocols {
                case .https:
                    httpResourceEndpointItem = endpoint
                case .wss:
                    wssResourceEndpointItem = endpoint
                case .unknown:
                    print("Error: Unknown endpoint protocol ", endpoint.protocols, "for endpoint" + endpoint.description())
                }
            }
            AWSMobileClient.default().getAWSCredentials { credentials, _ in
                self.AWSCredentials = credentials
            }
            
            var httpURlString = (wssResourceEndpointItem?.resourceEndpoint!)!
                + "?X-Amz-ChannelARN=" + self.channelARN!
            self.localSenderId = NSUUID().uuidString.lowercased()
            httpURlString += "&X-Amz-ClientId=" + self.localSenderId
            let httpRequestURL = URL(string: httpURlString)
            let wssRequestURL = URL(string: (wssResourceEndpointItem?.resourceEndpoint!)!)
            usleep(5)
            self.wssURL = KVSSigner
                .sign(signRequest: httpRequestURL!,
                      secretKey: (self.AWSCredentials?.secretKey)!,
                      accessKey: (self.AWSCredentials?.accessKey)!,
                      sessionToken: (self.AWSCredentials?.sessionKey)!,
                      wssRequest: wssRequestURL!,
                      region: region)
            
            let endpoint =
                AWSEndpoint(region: self.awsRegionType,
                            service: .KinesisVideo,
                            url: URL(string: httpResourceEndpointItem!.resourceEndpoint!))
            let configuration =
                AWSServiceConfiguration(region: self.awsRegionType,
                                        endpoint: endpoint,
                                        credentialsProvider: AWSMobileClient.default())
            AWSKinesisVideoSignaling.register(with: configuration!, forKey: awsKinesisVideoKey)
            let kvsSignalingClient = AWSKinesisVideoSignaling(forKey: awsKinesisVideoKey)

            let iceServerConfigRequest = AWSKinesisVideoSignalingGetIceServerConfigRequest.init()

            iceServerConfigRequest?.channelARN = channelARN
            iceServerConfigRequest?.clientId = self.localSenderId
            kvsSignalingClient.getIceServerConfig(iceServerConfigRequest!).continueWith(block: { (task) -> Void in
                if let error = task.error {
                    print("Error to get ice server config: \(error)")
                } else {
                    self.iceServerList = task.result!.iceServerList
                    print("ICE Server List : ", task.result!.iceServerList!)
                }
            }).waitUntilFinished()

        }).waitUntilFinished()
        
        
    }
    func getSingleMasterChannelEndpointRole() -> AWSKinesisVideoChannelRole {
        return .viewer
    }
    
    
}

public protocol AwsClientDelegate {
    func logonSuccess()
}

extension AwsSignallingClient: SignalClientDelegate {
    func signalClientDidConnect(_: SignalingClient) {
        signalingConnected = true
    }

    func signalClientDidDisconnect(_: SignalingClient) {
        signalingConnected = false
    }

    func setRemoteSenderClientId() {
        if self.remoteSenderClientId == nil {
            remoteSenderClientId = connectAsViewClientId
        }
    }
    
    func signalClient(_: SignalingClient, senderClientId: String, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp from [\(senderClientId)]")
        if !senderClientId.isEmpty {
            remoteSenderClientId = senderClientId
        }
        setRemoteSenderClientId()
        webRTCClient!.set(remoteSdp: sdp) { _ in
            print("Setting remote sdp and sending answer.")
            self.webRTCClient!.answer{ localSdp in
                self.signalingClient?.sendAnswer(rtcSdp: localSdp, recipientClientId: self.remoteSenderClientId!)
            }
         //  self.vc!.sendAnswer(recipientClientID: self.remoteSenderClientId!)

        }
    }

    func signalClient(_: SignalingClient, senderClientId: String, didReceiveCandidate candidate: RTCIceCandidate) {
        print("Received remote candidate from [\(senderClientId)]")
        if !senderClientId.isEmpty {
            remoteSenderClientId = senderClientId
        }
        setRemoteSenderClientId()
        webRTCClient!.set(remoteCandidate: candidate)
    }
}
extension AwsSignallingClient: WebRTCClientDelegate {
    func webRTCClient(_: WebRTCClient, didGenerate candidate: RTCIceCandidate) {
        print("Generated local candidate")
        setRemoteSenderClientId()
        signalingClient?.sendIceCandidate(rtcIceCandidate: candidate, master: false,
                                          recipientClientId: remoteSenderClientId!,
                                          senderClientId: self.localSenderId)
         
    }

    func webRTCClient(_: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        switch state {
        case .connected, .completed:
            print("WebRTC connected/completed state")
        case .disconnected:
            print("WebRTC disconnected state")
        case .new:
            print("WebRTC new state")
        case .checking:
            print("WebRTC checking state")
        case .failed:
            print("WebRTC failed state")
        case .closed:
            print("WebRTC closed state")
        case .count:
            print("WebRTC count state")
        @unknown default:
            print("WebRTC unknown state")
        }
    }

    func webRTCClient(_: WebRTCClient, didReceiveData _: Data) {
        print("Received local data")
    }
}

extension String {
    func trim() -> String {
        return trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}
