/**
 * Copyright 2016 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import IBMMobileFoundationSwift

class PreemptiveLoginChallengeHandler: SecurityCheckChallengeHandlerSwift {
    var isChallenged: Bool
    let defaults = UserDefaults.standard
    let securityCheckName = "UserLogin"
    
    
    init(){
        self.isChallenged = false
        super.init(securityCheck: "UserLogin");
        WLClientSwift.sharedInstance().registerChallengeHandler(challengeHandler: self)
        
        // Add notifications observers
        NotificationCenter.default.addObserver(self, selector: #selector(login(_:)), name: NSNotification.Name(rawValue: LoginNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logout), name: NSNotification.Name(rawValue: LogoutNotificationKey), object: nil)
    }
    
    // login (Triggered by Login Notification)
    @objc func login(_ notification:Notification){
        let userInfo = notification.userInfo as! Dictionary<String, AnyObject?>
        let username = userInfo["username"] as! String
        let password = userInfo["password"] as! String
        
        // If challenged use submitChallengeAnswer API, else use login API
        if(!self.isChallenged){
            WLAuthorizationManagerSwift.sharedInstance().login(securityCheck: self.securityCheckName, credentials: ["username": username, "password": password]) { (error) -> Void in
                if(error != nil){
                    NSLog("Login failed" + String(describing: error))
                }
            }
        }
        else{
            self.submitChallengeAnswer(["username": username, "password": password])
        }
    }
    
    // logout (Triggered by Logout Notification)
    @objc func logout(){
        WLAuthorizationManagerSwift.sharedInstance().logout(securityCheck: self.securityCheckName){
            (error) -> Void in
            if(error != nil){
                NSLog("Logout failed" + String(describing: error))
            }
            self.isChallenged = false
        }
        
    }
    
    // handleChallenge
    override open func handleChallenge(challengeResponse: [AnyHashable: Any]!) {
        self.isChallenged = true
        var errMsg: String!
        self.defaults.removeObject(forKey: "displayName")
        if(challengeResponse["errorMsg"] is NSNull){
            errMsg = ""
        }
        else{
            errMsg = (challengeResponse["errorMsg"] as! String)
        }
        let remainingAttempts = challengeResponse["remainingAttempts"]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: LoginRequiredNotificationKey), object: nil, userInfo: ["errorMsg":errMsg!, "remainingAttempts":remainingAttempts!])
        
    }
    
    // handleSuccess
    override open func handleSuccess(successResponse: [AnyHashable: Any]!) {
           
        self.isChallenged = false
        let user = successResponse["user"]  as! [String:Any]
        let displayName = user["displayName"] as! String
        print(displayName)
        self.defaults.set(displayName, forKey: "displayName")
        print(defaults)
        NotificationCenter.default.post(name: Notification.Name(rawValue: LoginSuccessNotificationKey), object: nil)
    }
    
    // handleFailure
    override open func handleFailure(failureResponse: [AnyHashable: Any]!) {
        self.isChallenged = false
        if let _ = failureResponse["failure"] as? String {
            NotificationCenter.default.post(name: Notification.Name(rawValue: LoginFailureNotificationKey), object: nil, userInfo: ["errorMsg":failureResponse["failure"]!])
        }
        else{
            NotificationCenter.default.post(name: Notification.Name(rawValue: LoginFailureNotificationKey), object: nil, userInfo: ["errorMsg":"Unknown error"])
        }
    }
}
