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

class ProtectedViewController: UIViewController {

    @IBOutlet weak var helloUserLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    
    let defaults = UserDefaults.standard
    var errMsg: String!
    var remainingAttempts: Int!
    
    // viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        // Add notifications observers
        NotificationCenter.default.addObserver(self, selector: #selector(loginRequired(_:)), name: NSNotification.Name(rawValue: LoginRequiredNotificationKey), object: nil)
    }
    
    // viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        if(defaults.string(forKey: "displayName") != nil){
            self.helloUserLabel.text = "Hello, " + defaults.string(forKey: "displayName")!
        }
        self.navigationItem.hidesBackButton = true;
    }


    @IBAction func getBalanceClicked(_ sender: UIButton) {
        let url = URL(string: "/adapters/ResourceAdapter/balance");
        let request = WLResourceRequest(url: url, method: WLHttpMethodGet);
        request?.send{ (response, error) -> Void in
            if(error != nil){
                NSLog("Failed to get balance. error: " + String(describing: error))
                self.balanceLabel.text = "Failed to get balance...";
            }
            else if(response != nil){
                self.balanceLabel.text = "Balance: " + (response?.responseText)!;
            }
        }
    }
    
    @IBAction func logoutClicked(_ sender: UIButton) {
       _ =  navigationController?.popViewController(animated: true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: LogoutNotificationKey), object: nil)
    }
    
    // loginRequired
    @objc func loginRequired(_ notification:Notification){
        let userInfo = notification.userInfo as! Dictionary<String, AnyObject?>
        self.errMsg =  (userInfo["errorMsg"] as! String)
        self.remainingAttempts = (userInfo["remainingAttempts"] as! Int)
        
        self.performSegue(withIdentifier: "TimedOutSegue", sender: nil)
    }
    
    // prepareForSegue (for TimedOutSegue)
    override func prepare(for segue: UIStoryboardSegue, sender: Any!)
    {
        if (segue.identifier == "TimedOutSegue") {
            if let destination = segue.destination as? LoginViewController{
                destination.errorViaSegue = self.errMsg
                destination.remainingAttemptsViaSegue = self.remainingAttempts
            }
        }
    }
    
    // viewDidDisappear
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
}
