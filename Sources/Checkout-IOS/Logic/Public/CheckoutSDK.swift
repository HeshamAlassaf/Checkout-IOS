//
//  CheckoutSDK.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import Foundation
import UIKit

public class CheckoutSDK {
    
    public init() {
        
    }
    
    public func start(configurations: [String : Any], delegate: CheckoutSDKDelegate) {
        let checkoutViewController = CheckoutViewController(configurations: configurations, results: self)
        delegate.controller.present(checkoutViewController, animated: true)
    }
}

extension CheckoutSDK: CheckoutSDKResults {
    
    func onClose() {
        print("onClose")
    }
    
    func onReady() {
        print("onSuccess")
    }
    
    func onSuccess(data: String) {
        print("onSuccess \(data)")
    }
    
    func onError(data: String) {
        print("onError \(data)")
    }
}


public protocol CheckoutSDKDelegate {
    var controller: UIViewController { get }
}
