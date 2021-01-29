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


public class AwsSignallingClient {
    	
    var delegate:AwsClientDelegate?
    let username, pw :String
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
    
    public func initAwsConfig(sucessCallBack:(()->(Void))?,errorCallBack:( ()->(Void))?){
        AWSDDLog.sharedInstance.logLevel = .verbose
        
        AWSMobileClient.default().initialize { (userState, error) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                errorCallBack?()
                return
            }
            sucessCallBack?()
        }
    }
    public func mobileLogin(){
        initAwsConfig(sucessCallBack: {() in
            
        }, errorCallBack: {() in 
            
        })
        
        /*
        AWSMobileClient.default().initialize { (userState, error) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            
            AWSMobileClient.default().signIn(username: self.username, password: self.pw) { (signInResult, error) in

                DispatchQueue.main.async {}
                
            }
        }*/
    }
}

public protocol AwsClientDelegate {
    func logonSuccess()
}
