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
import IBMMobileFirstPlatformFoundation

class LoginViewController: UIViewController {
    
    var errorViaSegue: String!
    var remainingAttemptsViaSegue: Int!
    var displayName: String!
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var remainingAttempts: UILabel!
    @IBOutlet weak var error: UILabel!
    
    // viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        self.username.text = ""
        self.password.text = ""
        self.remainingAttempts.text = ""
        self.error.text = ""
        if(self.remainingAttemptsViaSegue != nil) {
            self.remainingAttempts.text = "Remaining Attempts: " + String(self.remainingAttemptsViaSegue)
        }
        if(self.errorViaSegue != nil) {
            self.error.text = self.errorViaSegue
        }
        
        // Add notifications observers
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabels(_:)), name: NSNotification.Name(rawValue: LoginRequiredNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: LoginSuccessNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loginFailure(_:)), name: NSNotification.Name(rawValue: LoginFailureNotificationKey), object: nil)
    }
    
    // viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true;
    }
    
    // loginButtonClicked
    @IBAction func loginButtonClicked(_ sender: UIButton) {
        if(self.username.text != "" && self.password.text != ""){
            NotificationCenter.default.post(name: Notification.Name(rawValue: LoginNotificationKey), object: nil, userInfo: ["username": username.text!, "password": password.text!])
        }
    }
    
    // updateLabels (triggered by LoginRequired notification)
    @objc func updateLabels(_ notification:Notification){
        let userInfo = notification.userInfo as! Dictionary<String, AnyObject?>
        let errMsg = userInfo["errorMsg"] as! String
        let remainingAttempts = userInfo["remainingAttempts"] as! Int
        self.error.text = errMsg
        self.remainingAttempts.text = "Remaining Attempts: " + String(remainingAttempts)
    }
    
    // loginSuccess (triggered by LoginSuccess notification)
    @objc func loginSuccess(){
        self.performSegue(withIdentifier: "FromLoginToBalancePageSegue", sender: nil)
    }
    
    // cleanFieldsAndLabels (triggered by LoginFailure notification)
    @objc func loginFailure(_ notification:Notification){
        let userInfo = notification.userInfo as! Dictionary<String, AnyObject?>
        let errMsg = userInfo["errorMsg"] as! String
        
        let alert = UIAlertController(title: "Error",
                                      message: errMsg,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        self.username.text = ""
        self.password.text = ""
        self.remainingAttempts.text = ""
        self.error.text = ""
    }
    
    // viewDidDisappear
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

}
