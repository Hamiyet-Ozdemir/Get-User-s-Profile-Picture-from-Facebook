//
//  ViewController.swift
//  fbPicture
//
//  Created by Mac on 17.03.2022.
//

import UIKit
import FBSDKLoginKit

class ViewController: UIViewController, LoginButtonDelegate{
    
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var name:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let token = AccessToken.current,!token.isExpired {
            let token = token.tokenString
            let request = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                     parameters: ["fields" : "email, name"],
                                                     tokenString: token,
                                                     version: nil,
                                                     httpMethod: .get)
            request.start(completion: {connection,result,error in print("\(result)")})
        }
        
        let loginButton = FBLoginButton()
        loginButton.center = view.center
        loginButton.delegate = self
        loginButton.permissions = ["public_profile", "email"]
        view.addSubview(loginButton)
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        let token = result?.token?.tokenString
        //Login
        let request = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                 parameters: ["fields" : "email, name"],
                                                 tokenString: token,
                                                 version: nil,
                                                 httpMethod: .get)
        
        request.start(completion: {connection,result,error in print("\(result)")
        })
        
        //Profile picture request
        let request2 = GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email, picture.type(large)"])
        let _ = request2.start(completion: { (connection, result, error) in
            guard let userInfo = result as? [String: Any] else { return } //handle the error
            
            //get user name and profile picture
            var userFacebookDict = result as! NSDictionary
            let userName = userFacebookDict["name"]! as! String
            self.name = userName
            
            //The url is nested 3 layers deep into the result so it's pretty messy
            if let imageURL = ((userInfo["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String {
                //Download image from imageURL
                self.imageView.downloaded(from: imageURL)
                self.labelName.text = self.name
            }
        })
    }
    
    
    //When user log out delete name and image
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        self.imageView.image = .none
        self.labelName.text = ""
    }
    
    
    
    
}

//Extension for the imageview to download
extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}
