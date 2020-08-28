//
//  ViewController.swift
//  ParseSignInWithApple
//
//  Created by Venom on 27/08/20.
//  Copyright © 2020 Venom. All rights reserved.
//

import UIKit
import AuthenticationServices
import Parse

class AuthDelegate:NSObject, PFUserAuthenticationDelegate {
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true
    }
    
    func restoreAuthenticationWithAuthData(authData: [String : String]?) -> Bool {
        return true
    }
}

class ViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Sign In with Apple button
        let signInWithAppleButton = ASAuthorizationAppleIDButton()

        // set this so the button will use auto layout constraint
        signInWithAppleButton.translatesAutoresizingMaskIntoConstraints = false

        // add the button to the view controller root view
        self.view.addSubview(signInWithAppleButton)

        // set constraint
        NSLayoutConstraint.activate([
            signInWithAppleButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50.0),
            signInWithAppleButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50.0),
            signInWithAppleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70.0),
            signInWithAppleButton.heightAnchor.constraint(equalToConstant: 50.0)
        ])

        // the function that will be executed when user tap the button
        signInWithAppleButton.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        PFUser.register(AuthDelegate(), forAuthType: "apple")

        // This block is used in case the user has logged in before. It works in conjunction with code in line 105
        if let userID = UserDefaults.standard.string(forKey: "userID") {
            // get the login status of Apple sign in for the app
            // asynchronous
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID, completion: {
                credentialState, error in

                switch(credentialState){
                case .authorized:
                    print("user remain logged in, proceed to another view")
                    self.performSegue(withIdentifier: "LoginToUserSegue", sender: nil)
                case .revoked:
                    print("user logged in before but revoked")
                case .notFound:
                    print("user haven't log in before")
                default:
                    print("unknown state")
                }
            })
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // return the current view window
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("authorization error")
        guard let error = error as? ASAuthorizationError else {
            return
        }

        switch error.code {
        case .canceled:
            // user press "cancel" during the login prompt
            print("Canceled")
        case .unknown:
            // user didn't login their Apple ID on the device
            print("Unknown")
        case .invalidResponse:
            // invalid response received from the login
            print("Invalid Respone")
        case .notHandled:
            // authorization request not handled, maybe internet failure during login
            print("Not handled")
        case .failed:
            // authorization failed
            print("Failed")
        @unknown default:
            print("Default")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // unique ID for each user, this uniqueID will always be returned
            let userID = appleIDCredential.user
            print("UserID: " + userID)
            
            // if needed, save it to user defaults by uncommenting the line below
            //UserDefaults.standard.set(appleIDCredential.user, forKey: "userID")
            
            // optional, might be nil
            let email = appleIDCredential.email
            print("Email: " + (email ?? "no email") )
            
            // optional, might be nil
            let givenName = appleIDCredential.fullName?.givenName
            print("Given Name: " + (givenName ?? "no given name") )
            
            // optional, might be nil
            let familyName = appleIDCredential.fullName?.familyName
            print("Family Name: " + (familyName ?? "no family name") )
            
            // optional, might be nil
            let nickName = appleIDCredential.fullName?.nickname
            print("Nick Name: " + (nickName ?? "no nick name") )
            /*
                useful for server side, the app can send identityToken and authorizationCode
                to the server for verification purpose
            */
            var identityToken : String?
            if let token = appleIDCredential.identityToken {
                identityToken = String(bytes: token, encoding: .utf8)
                print("Identity Token: " + (identityToken ?? "no identity token"))
            }

            var authorizationCode : String?
            if let code = appleIDCredential.authorizationCode {
                authorizationCode = String(bytes: code, encoding: .utf8)
                print("Authorization Code: " + (authorizationCode ?? "no auth code") )
            }

            // do what you want with the data here
            
            PFUser.logInWithAuthType(inBackground: "apple", authData: ["token": String(identityToken!), "id": userID]).continueWith { task -> Any? in
                if ((task.error) != nil){
                    //DispatchQueue.main.async {
                        print("Could not login.\nPlease try again.")
                        print("Error with parse login after SIWA: \(task.error!.localizedDescription)")
                    //}
                    return task
                }
                print("Successfuly signed in with Apple")
                return nil
            }
        }
    }
    
    // This is the function that will be executed when user taps the button
    @objc func appleSignInTapped() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        // request full name and email from the user's Apple ID
        request.requestedScopes = [.fullName, .email]

        // pass the request to the initializer of the controller
        let authController = ASAuthorizationController(authorizationRequests: [request])
        
        // similar to delegate, this will ask the view controller
        // which window to present the ASAuthorizationController
        authController.presentationContextProvider = self
        
        // delegate functions will be called when user data is
        // successfully retrieved or error occured
        authController.delegate = self
          
        // show the Sign-in with Apple dialog
        authController.performRequests()
    }
}
