//
//  GoogleAuthManager.swift
//  community
//
//  Created by Illia Kniaziev on 18.02.2022.
//

import Firebase
import FirebaseAuth
import GoogleSignIn
import RxSwift

class GoogleAuthManager {
    
    enum SignInState {
        case signedIn
        case signedOut
    }
    
    private init() {
        state.on(.next(.signedOut))
    }
    
    static let shared = GoogleAuthManager()
    let state = PublishSubject<SignInState>()
    
    func signIn() {
        if !restoreUser() {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }

            let configuration = GIDConfiguration(clientID: clientID)

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }

            GIDSignIn.sharedInstance.signIn(with: configuration, presenting: rootViewController) { [unowned self] user, error in
                authenticateUser(for: user, with: error)
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        state.on(.next(.signedOut))
    }
    
    @discardableResult
    private func restoreUser() -> Bool {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [unowned self] user, error in
                authenticateUser(for: user, with: error)
            }
            let user = GIDSignIn.sharedInstance.currentUser
            print(user?.profile?.name ?? "):")
        }
        
        return GIDSignIn.sharedInstance.hasPreviousSignIn()
    }
    
    private func authenticateUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }

        guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)

        Auth.auth().signIn(with: credential) { [unowned self] (_, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                state.on(.next(.signedIn))
                let user = GIDSignIn.sharedInstance.currentUser
                print(user?.profile?.name ?? "):")
            }
        }
    }
}
