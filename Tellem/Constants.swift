//
//  Constants.swift
//  Tellem
//
//  Created by Brian Castles on 1/18/16.
//  Copyright © 2016 Brian Castles. All rights reserved.
//

import Foundation
import AWSCore

struct Constants {
    
    // MARK: Required: Amazon Cognito Configuration
    
    static let COGNITO_REGIONTYPE = AWSRegionType.USEast1
    static let COGNITO_IDENTITY_POOL_ID = "us-east-1:2f0a708d-9c38-4cec-8629-ea15dd5942d5"

    // MARK: Optional: Enable Facebook Login

    static let FACEBOOK_CLIENT_ID = "890511954380228"

    /**
     * OPTIONAL: Enable Developer Authentication Login
     *
     * This sample uses the Java-based Cognito Authentication backend
     * To enable Dev Auth Login
     * 1. Set the values for the constants below to match the running instance
     *    of the example developer authentication backend
     */
     // This is the default value, if you modified your backend configuration
     // update this value as appropriate
    static let DEVELOPER_AUTH_APP_NAME = "Tellem"
    // Update this value to reflect where your backend is deployed
    // !!!!!!!!!!!!!!!!!!!
    // Make sure to enable HTTPS for your end point before deploying your
    // app to production.
    // !!!!!!!!!!!!!!!!!!!
    static let DEVELOPER_AUTH_ENDPOINT = "http://YOUR_ENDPOINT"
    // Set to the provider name you configured in the Cognito console.
    static let DEVELOPER_AUTH_PROVIDER_NAME = "YOUR_PROVIDER_NAME"
    
    /*******************************************
     * DO NOT CHANGE THE VALUES BELOW HERE
     */
    
    static let DEVICE_TOKEN_KEY = "DeviceToken"
    static let COGNITO_DEVICE_TOKEN_KEY = "CognitoDeviceToken"
    static let COGNITO_PUSH_NOTIF = "CognitoPushNotification"
    static let GOOGLE_CLIENT_SCOPE = "https://www.googleapis.com/auth/userinfo.profile"
    static let GOOGLE_OIDC_SCOPE = "openid"
    
}