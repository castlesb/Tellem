//
//  AmazonClientManager.swift
//  Tellem
//
//  Created by Brian Castles on 1/18/16.
//  Copyright © 2016 Brian Castles. All rights reserved.
//

import Foundation
import UICKeyChainStore
import AWSCore
import AWSCognito
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit

class AmazonClientManager : NSObject, AIAuthenticationDelegate {
    static let sharedInstance = AmazonClientManager()
    
    enum Provider: String {
        case FB
    }
    
    //KeyChain Constants
    let FB_PROVIDER = Provider.FB.rawValue
    
    //Properties
    var keyChain: UICKeyChainStore
    var completionHandler: AWSContinuationBlock?
    var fbLoginManager: FBSDKLoginManager?
    var credentialsProvider: AWSCognitoCredentialsProvider?
    var devAuthClient: DeveloperAuthenticationClient?
    var loginViewController: UIViewController?
    
    
    override init() {
        keyChain = UICKeyChainStore(service: NSBundle.mainBundle().bundleIdentifier!)
        devAuthClient = DeveloperAuthenticationClient(appname: Constants.DEVELOPER_AUTH_APP_NAME, endpoint: Constants.DEVELOPER_AUTH_ENDPOINT)
        
        super.init()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: General Login
    
    func isConfigured() -> Bool {
        return !(Constants.COGNITO_IDENTITY_POOL_ID == "us-east-1:2f0a708d-9c38-4cec-8629-ea15dd5942d5" || Constants.COGNITO_REGIONTYPE == AWSRegionType.USEAST1)
    }
    
    func resumeSession(completionHandler: AWSContinuationBlock) {
        self.completionHandler = completionHandler
        
        if self.keyChain[FB_PROVIDER] != nil {
            self.reloadFBSession()
        }
        
        if self.credentialsProvider == nil {
            self.completeLogin(nil)
        }
    }
    
    //Sends the appropriate URL based on login provider
    func application(application: UIApplication,
        openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {

            
            if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
                return true
            }

            return false
    }
    
    func completeLogin(logins: [NSObject : AnyObject]?) {
        var task: AWSTask?
        
        if self.credentialsProvider == nil {
            task = self.initializeClients(logins)
        } else {
            var merge = [NSObject : AnyObject]()
            
            //Add existing logins
            if let previousLogins = self.credentialsProvider?.logins {
                merge = previousLogins
            }
            
            //Add new logins
            if let unwrappedLogins = logins {
                for (key, value) in unwrappedLogins {
                    merge[key] = value
                }
                self.credentialsProvider?.logins = merge
            }
            //Force a refresh of credentials to see if merge is necessary
            task = self.credentialsProvider?.refresh()
        }
        task?.continueWithBlock {
            (task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                let userDefaults = NSUserDefaults.standardUserDefaults()
                let currentDeviceToken: NSData? = userDefaults.objectForKey(Constants.DEVICE_TOKEN_KEY) as? NSData
                var currentDeviceTokenString : String
                
                if currentDeviceToken != nil {
                    currentDeviceTokenString = currentDeviceToken!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
                } else {
                    currentDeviceTokenString = ""
                }
                
                if currentDeviceToken != nil && currentDeviceTokenString != userDefaults.stringForKey(Constants.COGNITO_DEVICE_TOKEN_KEY) {
                    
                    AWSCognito.defaultCognito().registerDevice(currentDeviceToken).continueWithBlock { (task: AWSTask!) -> AnyObject! in
                        if (task.error == nil) {
                            userDefaults.setObject(currentDeviceTokenString, forKey: Constants.COGNITO_DEVICE_TOKEN_KEY)
                            userDefaults.synchronize()
                        }
                        return nil
                    }
                }
            }
            return task
            }.continueWithBlock(self.completionHandler)
    }
    
    func initializeClients(logins: [NSObject : AnyObject]?) -> AWSTask? {
        print("Initializing Clients...")
        
        AWSLogger.defaultLogger().logLevel = AWSLogLevel.Verbose
        
        let identityProvider = DeveloperAuthenticatedIdentityProvider(
            regionType: Constants.COGNITO_REGIONTYPE,
            identityId: nil,
            identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID,
            logins: logins,
            providerName: Constants.DEVELOPER_AUTH_PROVIDER_NAME,
            authClient: self.devAuthClient)
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityProvider: identityProvider, unauthRoleArn: nil, authRoleArn: nil)
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        return self.credentialsProvider?.getIdentityId()
    }
    
    func loginFromView(theViewController: UIViewController, withCompletionHandler completionHandler: AWSContinuationBlock) {
        self.completionHandler = completionHandler
        self.loginViewController = theViewController
        self.displayLoginSheet()
    }
    
    func logOut(completionHandler: AWSContinuationBlock) {
        if self.isLoggedInWithFacebook() {
            self.fbLogout()
        }
        self.devAuthClient?.logout()
        
        // Wipe credentials
        self.credentialsProvider?.logins = nil
        AWSCognito.defaultCognito().wipe()
        self.credentialsProvider?.clearKeychain()
        
        AWSTask(result: nil).continueWithBlock(completionHandler)
    }
    
    func isLoggedIn() -> Bool {
        return isLoggedInWithFacebook()
    }
    
    // MARK: Facebook Login
    
    func isLoggedInWithFacebook() -> Bool {
        let loggedIn = FBSDKAccessToken.currentAccessToken() != nil
        
        return self.keyChain[FB_PROVIDER] != nil && loggedIn
    }
    
    func reloadFBSession() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            print("Reloading Facebook Session")
            self.completeFBLogin()
        }
    }
    
    func fbLogin() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            self.completeFBLogin()
        } else {
            if self.fbLoginManager == nil {
                self.fbLoginManager = FBSDKLoginManager()
                self.fbLoginManager?.logInWithReadPermissions(nil) {
                    (result: FBSDKLoginManagerLoginResult!, error : NSError!) -> Void in
                    
                    if (error != nil) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.errorAlert("Error logging in with FB: " + error.localizedDescription)
                        }
                    } else if result.isCancelled {
                        //Do nothing
                    } else {
                        self.completeFBLogin()
                    }
                }
            }
        }
        
    }
    
    func fbLogout() {
        if self.fbLoginManager == nil {
            self.fbLoginManager = FBSDKLoginManager()
        }
        self.fbLoginManager?.logOut()
        self.keyChain[FB_PROVIDER] = nil
    }
    
    func completeFBLogin() {
        self.keyChain[FB_PROVIDER] = "YES"
        self.completeLogin(["graph.facebook.com" : FBSDKAccessToken.currentAccessToken().tokenString])
    }
    
    func displayLoginSheet() {
        let loginProviders = UIAlertController(title: nil, message: "Login With:", preferredStyle: .ActionSheet)
        let fbLoginAction = UIAlertAction(title: "Facebook", style: .Default) {
            (alert: UIAlertAction) -> Void in
            self.fbLogin()
        }
        let googleLoginAction = UIAlertAction(title: "Google", style: .Default) {
            (alert: UIAlertAction) -> Void in
            self.googleLogin()
        }
        let amazonLoginAction = UIAlertAction(title: "Amazon", style: .Default) {
            (alert: UIAlertAction) -> Void in
            self.amazonLogin()
        }
        let twitterLoginAction = UIAlertAction(title: "Twitter", style: .Default) {
            (alert: UIAlertAction) -> Void in
            self.twitterLogin()
        }
        let digitsLoginAction = UIAlertAction(title: "Digits", style: .Default) {
            (alert: UIAlertAction) -> Void in
            self.digitsLogin()
        }
        let byoiLoginAction = UIAlertAction(title: "Developer Authenticated", style: .Default) {
            (alert: UIAlertAction) -> Void in
            self.BYOILogin()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) {
            (alert: UIAlertAction!) -> Void in
            AWSTask(result: nil).continueWithBlock(self.completionHandler)
        }
        
        loginProviders.addAction(fbLoginAction)
        
        self.loginViewController?.presentViewController(loginProviders, animated: true, completion: nil)
    }
    
    func errorAlert(message: String) {
        let errorAlert = UIAlertController(title: "Error", message: "\(message)", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Ok", style: .Default) { (alert: UIAlertAction) -> Void in }
        
        errorAlert.addAction(okAction)
        
        self.loginViewController?.presentViewController(errorAlert, animated: true, completion: nil)
    }
    
    
}