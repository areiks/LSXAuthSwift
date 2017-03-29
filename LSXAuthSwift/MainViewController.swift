//
//  ViewController.swift
//  LSXAuthSwift
//
//  Created by Lukasz Skierkowski on 28.03.2017.
//  Copyright © 2017 Lukasz Skierkowski. All rights reserved.
//

import UIKit
import Alamofire

class MainViewController: UIViewController {

    @IBOutlet var loginLabel: UILabel!
    @IBOutlet var loginTextField: UITextField!
    @IBOutlet var passwordLabel: UILabel!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var authenticateButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.activityIndicator.isHidden = true;
    }

    @IBAction func authenticateButtonClicked(_ sender: Any) {
        
        disableUserInteraction(disable: true)
        
        let password = passwordTextField.text ?? ""
        let login = loginTextField.text ?? ""
        let accessTokenUrl = "https://www.instapaper.com/api/1/oauth/access_token"
        let verifyCredentialsUrl = "https://www.instapaper.com/api/1/account/verify_credentials"
        
        if !(login.characters.count > 0) {
            //but password for Instapaper can be empty
            self.showError(message: "Please enter the login before trying to authenticate.")
            
        } else if !LSXAuthSwift.isAccessTokenAvailable() {

            let params = ["x_auth_username" : login, "x_auth_password" : password, "x_auth_mode":"client_auth"]
            
            var authorizationHeader = LSXAuthSwift.generateAuthorizationHeader(url: accessTokenUrl, params: params)
            
            var headers = [
                "Authorization" : authorizationHeader,
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
            ]
            
            Alamofire.request(accessTokenUrl, method: .post, parameters: params, encoding: URLEncoding.default, headers: headers).responseString { (response) in
                
                debugPrint(response)
                
                if (response.error != nil) {
                    self.showError(message: response.error!.localizedDescription)
                    
                } else if (response.value?.contains("oauth_token") ?? false) {
                    
                    //just test
                    
                    let responseString = response.value!
                    let responseComponents = responseString.components(separatedBy: "&")
                    let oauthToken = responseComponents[1].components(separatedBy: "=")
                    let oauthTokenSecret = responseComponents[0].components(separatedBy: "=")
                    
                    LSXAuthSwift.setOauthToken(oauthToken: oauthToken[1], oauthTokenSecret: oauthTokenSecret[1])
                    self.hideLoginItems()
                    
                    authorizationHeader = LSXAuthSwift.generateAuthorizationHeader(url: verifyCredentialsUrl)
                    
                    headers = [
                        "Authorization" : authorizationHeader,
                        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
                        "Accept":"application/json"
                    ]
                    
                    Alamofire.request(verifyCredentialsUrl, method: .post, parameters: [:], encoding: URLEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                        debugPrint(response)
                        self.showInfo(message: response.description)
                    })
                } else {
                    self.showError(message: "Response does not contain the token, please check your login and password.")
                }
            }

        } else {
            let authorizationHeader = LSXAuthSwift.generateAuthorizationHeader(url: verifyCredentialsUrl)
            
            let headers = [
                "Authorization" : authorizationHeader,
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
                "Accept":"application/json"
            ]
            
            Alamofire.request("https://www.instapaper.com/api/1/account/verify_credentials", method: .post, parameters: [:], encoding: URLEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                debugPrint(response)
                self.showInfo(message: response.description)
            })
        }

    }
    
    func disableUserInteraction(disable: Bool) {
        self.loginTextField.isEnabled = !disable
        self.passwordTextField.isEnabled = !disable
        self.authenticateButton.isEnabled = !disable
        self.activityIndicator.isHidden = !disable
        
        if (disable) {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
        
    }
    
    func hideLoginItems() {
        self.loginLabel.isHidden = true
        self.loginTextField.isHidden = true
        self.passwordLabel.isHidden = true
        self.passwordTextField.isHidden = true
        self.authenticateButton.setTitle("Verify", for: .normal)
    }
    
    func showError(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        {
            (result : UIAlertAction) -> Void in
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        
        disableUserInteraction(disable: false)
    }
    
    func showInfo(message: String) {
        let alertController = UIAlertController(title: "Info", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        {
            (result : UIAlertAction) -> Void in
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        
        disableUserInteraction(disable: false)
    }

}

