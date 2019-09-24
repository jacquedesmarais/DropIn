//
//  ViewController.swift
//  DropIn
//
//  Created by Desmarais, Jacque on 5/24/18.
//  Copyright © 2018 Desmarais, Jacque. All rights reserved.
//

import UIKit
import BraintreeDropIn
import Braintree

class ViewController: UIViewController {
    var clientToken:String!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var payButton: UIButton! {
        didSet {
            payButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -42, bottom: 0, right: 0)
            payButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -12, bottom: 0, right: 0)
            payButton.layer.cornerRadius = payButton.bounds.midY
            payButton.layer.masksToBounds = true
        }
    }
    
    class ViewController: UIViewController, BTViewControllerPresentingDelegate {

        func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
            present(viewController, animated: true, completion: nil)
        }
        
        func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
        var paymentFlowDriver: BTPaymentFlowDriver!
        
    }

    // Optional - display and hide loading indicator UI
    func appSwitcherWillPerformAppSwitch(_ appSwitcher: Any) {
        showLoadingUI()

        NotificationCenter.default.addObserver(self, selector: #selector(hideLoadingUI), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    func appSwitcherWillProcessPaymentInfo(_ appSwitcher: Any) {
        hideLoadingUI()
    }

    func appSwitcher(_ appSwitcher: Any, didPerformSwitchTo target: BTAppSwitchTarget) {

    }

    // MARK: - Private methods

    func showLoadingUI() {
        // ...
    }

    @objc func hideLoadingUI() {
        NotificationCenter
            .default
            .removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        // ...
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        amountTextField.becomeFirstResponder()
    }
    
    func fetchClientToken() {
        let clientTokenURL = URL(string: "http://localhost:8000/client_token.php")!
        let clientTokenRequest = NSMutableURLRequest(url: clientTokenURL as URL)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            let clientToken = String(data: data!, encoding: String.Encoding.utf8)
            print(clientToken!) // print client token to console
            self.showDropIn(clientToken: clientToken!)
            }.resume()
    }
    
    @IBAction func pay(_ sender: Any) {
        fetchClientToken()
    }
    
    func showDropIn(clientToken: String) {
        let request =  BTDropInRequest()
        request.threeDSecureVerification = true
        
        let threeDSecureRequest = BTThreeDSecureRequest()
        threeDSecureRequest.threeDSecureRequestDelegate = self as? BTThreeDSecureRequestDelegate
        
        let threeDSecureAmount = NSDecimalNumber(string: self.amountTextField.text!)
        threeDSecureRequest.amount = threeDSecureAmount
        threeDSecureRequest.email = "test@example.com"
        threeDSecureRequest.versionRequested = .version2
        
        let address = BTThreeDSecurePostalAddress()
        address.givenName = "Jill"
        address.surname = "Doe"
        address.phoneNumber = "5551234567"
        address.streetAddress = "555 Smith St"
        address.extendedAddress = "#2"
        address.locality = "Chicago"
        address.region = "IL"
        address.postalCode = "12345"
        address.countryCodeAlpha2 = "US"
        threeDSecureRequest.billingAddress = address
        
        // Optional additional information.
        // For best results, provide as many of these elements as possible.
        let additionalInformation = BTThreeDSecureAdditionalInformation()
        additionalInformation.shippingAddress = address
        threeDSecureRequest.additionalInformation = additionalInformation
        
        request.threeDSecureRequest = threeDSecureRequest
//        request.vaultManager = true
//        request.cardholderNameSetting = .required
        let dropIn = BTDropInController(authorization: clientToken, request: request)
        { [unowned self] (controller, result, error) in
            
            if let error = error {
                self.show(message: error.localizedDescription)
             
            } else if (result?.isCancelled == true) {
                self.show(message: "Transaction Cancelled")
                
            } else if let nonce = result?.paymentMethod?.nonce, let amount = self.amountTextField.text {
                self.sendRequestPaymentToServer(nonce: nonce, amount: amount)
             			print(nonce)
            }
            controller.dismiss(animated: true, completion: nil)
        }
        DispatchQueue.main.async {
        	self.present(dropIn!, animated: true, completion: nil)
    	}
    }
    
    func sendRequestPaymentToServer(nonce: String, amount: String) {
        activityIndicator.startAnimating()
        
     let paymentURL = URL(string: "http://localhost:8000/pay.php")!
        var request = URLRequest(url: paymentURL)
        request.httpBody = "payment_method_nonce=\(nonce)&amount=\(amount)".data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) -> Void in
            guard let data = data else {
                self?.show(message: error!.localizedDescription)
                return
            }
         
         guard let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let success = result?["success"] as? Bool, success == true else {
                self?.show(message: "Transaction failed. Please try again.")
                return
            }
            	// print the result to the console
            	print(result!);
            self?.show(message: "Successfully charged. Thanks So Much :)")
            }.resume()
    }
 
    func show(message: String) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            
            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
