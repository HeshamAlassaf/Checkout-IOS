//
//  ViewController.swift
//  CheckoutExample
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import UIKit
import Checkout_IOS
import SnapKit

class ViewController: UIViewController {

    private lazy var checkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Checkout", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(startCheckout), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(checkoutButton)
        
        checkoutButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
    
    @objc private func startCheckout() {
        // Example configurations - replace with your actual configuration
        let configurations:[String:Any] = [
            "open": true,
            "hashString": "",
            "checkoutMode": "page",
            "language": "en",
            "themeMode": "light",
            "supportedPaymentMethods": "ALL",
            "paymentType": "ALL",
            "selectedCurrency": "KWD",
            "supportedCurrencies": "ALL",
            "gateway": [
                "publicKey": "pk_test_ohzQrUWRnTkCLD1cqMeudyjX",
                "merchantId": ""
            ],
            "customer": [
                "firstName": "Android",
                "lastName": "Test",
                "email": "example@gmail.com",
                "phone": [
                    "countryCode": "965",
                    "number": "55567890"
                ]
            ],
            "transaction": [
                "mode": "charge",
                "charge": [
                    "saveCard": true,
                    "auto": [
                        "type": "VOID",
                        "time": 100
                    ],
                    "redirect": [
                        "url": "https://demo.staging.tap.company/v2/sdk/checkout"
                    ],
                    "threeDSecure": true,
                    "subscription": [
                        "type": "SCHEDULED",
                        "amount_variability": "FIXED",
                        "txn_count": 0
                    ],
                    "airline": [
                        "reference": [
                            "booking": ""
                        ]
                    ]
                ]
            ],
            "amount": "5",
            "order": [
                "id": "",
                "currency": "KWD",
                "amount": "5",
                "items": [
                    [
                        "amount": "5",
                        "currency": "KWD",
                        "name": "Item Title 1",
                        "quantity": 1,
                        "description": "item description 1"
                    ]
                ]
            ],
            "cardOptions": [
                "showBrands": true,
                "showLoadingState": false,
                "collectHolderName": true,
                "preLoadCardName": "",
                "cardNameEditable": true,
                "cardFundingSource": "all",
                "saveCardOption": "all",
                "forceLtr": false,
                "alternativeCardInputs": [
                    "cardScanner": true,
                    "cardNFC": true
                ]
            ],
            "isApplePayAvailableOnClient": true,
        ]
        CheckoutSDK().start(configurations: configurations, delegate: self)

    }
}

// MARK: - CheckoutSDKDelegate
extension ViewController: CheckoutSDKDelegate {
    var controller: UIViewController {
        return self
    }
}
