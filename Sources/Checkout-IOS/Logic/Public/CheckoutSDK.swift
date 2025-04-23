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
        let checkoutViewController = CheckoutViewController(configurations: configurations)
        delegate.controller.present(checkoutViewController, animated: true)
    }
}


public protocol CheckoutSDKDelegate {
    var controller: UIViewController { get }
}
