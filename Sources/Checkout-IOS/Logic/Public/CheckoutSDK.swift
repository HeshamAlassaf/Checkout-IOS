//
//  CheckoutSDK.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import Foundation
import UIKit

public class CheckoutSDK {
    public init(configurations: [String : Any], delegate: CheckoutSDKDelegate) {
        let checkoutViewController = CheckoutViewController(configurations: configurations, results: self)
        delegate.controller.present(checkoutViewController, animated: true)
    }
}

extension CheckoutSDK: CheckoutSDKResults {
    func onReady() {
        
    }
}


public protocol CheckoutSDKDelegate {
    var controller: UIViewController { get }
}
