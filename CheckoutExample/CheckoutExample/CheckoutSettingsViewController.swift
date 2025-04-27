//
//  CheckoutSettingsViewController.swift
//  CheckoutExample
//
//  Created by MahmoudShaabanAllam on 27/04/2025.
//

import UIKit
import Eureka

protocol CheckoutSettingsViewControllerDelegate: AnyObject {
    func checkoutSettingsViewControllerDidSave(_ config: [String:Any])
}

class CheckoutSettingsViewController: FormViewController {
    
    var config: [String:Any]?
    var delegate: CheckoutSettingsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Basic settings section
        form +++ Section("Basic Settings")
        <<< SwitchRow("open"){ row in
            row.title = "Open"
            row.value = self.config?["open"] as? Bool ?? true
            row.onChange { row in
                self.config?["open"] = row.value ?? true
            }
        }
        <<< TextRow("hashString"){ row in
            row.title = "Hash String"
            row.placeholder = "Enter hash string"
            row.value = self.config?["hashString"] as? String ?? ""
            row.onChange { row in
                self.config?["hashString"] = row.value ?? ""
            }
        }
        <<< SegmentedRow<String>("checkoutMode"){ row in
            row.title = "Checkout Mode"
            row.options = ["page", "popup"]
            row.value = self.config?["checkoutMode"] as? String ?? "page"
            row.onChange { row in
                self.config?["checkoutMode"] = row.value ?? "page"
            }
        }
        <<< SegmentedRow<String>("language"){ row in
            row.title = "Language"
            row.options = ["en", "ar"]
            row.value = self.config?["language"] as? String ?? "en"
            row.onChange { row in
                self.config?["language"] = row.value ?? "en"
            }
        }
        <<< ActionSheetRow<String>("themeMode"){ row in
            row.title = "Theme Mode"
            row.options = ["light", "dark", "light_mono", "dark_colored", "auto"]
            row.value = self.config?["themeMode"] as? String ?? "light"
            row.onChange { row in
                self.config?["themeMode"] = row.value ?? "light"
            }
        }
        <<< SwitchRow("useAllPaymentMethods") { row in
            row.title = "Use All Payment Methods"
            row.value = (self.config?["supportedPaymentMethods"] as? String ?? "") == "ALL"
            row.onChange { row in
                if let isAll = row.value, isAll {
                    self.config?["supportedPaymentMethods"] = "ALL"
                    // Hide the multiple selector when "ALL" is selected
                    let multiSelectorRow: MultipleSelectorRow<String> = self.form.rowBy(tag: "specificPaymentMethods")!
                    multiSelectorRow.hidden = true
                    multiSelectorRow.evaluateHidden()
                } else {
                    // Show the multiple selector when specific methods should be selected
                    let multiSelectorRow: MultipleSelectorRow<String> = self.form.rowBy(tag: "specificPaymentMethods")!
                    multiSelectorRow.hidden = false
                    multiSelectorRow.evaluateHidden()
                    
                    // If switching from ALL to specific, update the config with the current selections
                    if let selectedValues = multiSelectorRow.value, !selectedValues.isEmpty {
                        self.config?["supportedPaymentMethods"] = selectedValues.joined(separator: ",")
                    } else {
                        // Default to VISA if nothing selected
                        self.config?["supportedPaymentMethods"] = "VISA"
                        multiSelectorRow.value = ["VISA"]
                        multiSelectorRow.updateCell()
                    }
                }
            }
        }
        
        <<< MultipleSelectorRow<String>("specificPaymentMethods") { row in
            row.title = "Select Payment Methods"
            row.options = CheckoutSettingsViewController.supportedPaymentMethods
            // Set initial selections based on current config
            let currentValue = self.config?["supportedPaymentMethods"] as? String
            if currentValue != "ALL" {
                let values = self.config?["supportedPaymentMethods"] as? [String] ?? []
                row.value = Set(values)
            }
            
            // Hide this row if "ALL" is selected
            row.hidden = Condition.function(["useAllPaymentMethods"], { form in
                return (form.rowBy(tag: "useAllPaymentMethods") as? SwitchRow)?.value == true
            })
            
            row.onChange { row in
                if let selectedValues = row.value, !selectedValues.isEmpty {
                    self.config?["supportedPaymentMethods"] = Array(selectedValues)
                } else {
                    // If nothing selected, switch back to ALL
                    self.config?["supportedPaymentMethods"] = "ALL"
                    let allSwitch: SwitchRow = self.form.rowBy(tag: "useAllPaymentMethods")!
                    allSwitch.value = true
                    allSwitch.updateCell()
                    row.hidden = true
                    row.evaluateHidden()
                }
            }
        }
        <<< ActionSheetRow<String>("paymentType"){ row in
            row.title = "Payment Type"
            row.options = ["ALL", "WEB", "CARD", "DEVICE"]
            row.value = self.config?["paymentType"] as? String ?? "ALL"
            row.onChange { row in
                self.config?["paymentType"] = row.value ?? "ALL"
            }
        }
        <<< ActionSheetRow<String>("selectedCurrency"){ row in
            row.title = "Selected Currency"
            
            // Get supported currencies from config
            let supportedCurrenciesString = self.config?["supportedCurrencies"] as? String ?? "ALL"
            var currencyOptions: [String] = ["KWD", "USD", "SAR", "BHD", "QAR", "AED", "OMR", "JOD", "EGP"]
            
            // If supportedCurrencies is not "ALL", use the specified currencies
            if supportedCurrenciesString != "ALL" {
                currencyOptions = supportedCurrenciesString.components(separatedBy: ",")
            }
            
            row.options = currencyOptions
            row.value = self.config?["selectedCurrency"] as? String ?? "KWD"
            row.onChange { row in
                self.config?["selectedCurrency"] = row.value ?? "KWD"
            }
        }
        <<< TextRow("supportedCurrencies"){ row in
            row.title = "Supported Currencies"
            row.placeholder = "ALL or comma-separated list"
            row.value = self.config?["supportedCurrencies"] as? String ?? "ALL"
            row.onChange { row in
                self.config?["supportedCurrencies"] = row.value ?? "ALL"
            }
        }
        <<< TextRow("amount"){ row in
            row.title = "Amount"
            row.placeholder = "Enter amount"
            row.value = self.config?["amount"] as? String ?? "5"
            row.onChange { row in
                self.config?["amount"] = row.value ?? "5"
            }
        }
        
        // Gateway section
        form +++ Section("Gateway")
        <<< TextRow("gateway.publicKey"){ row in
            row.title = "Public Key"
            row.placeholder = "Enter your public key here"
            row.value = (config?["gateway"] as? [String: Any])?["publicKey"] as? String ?? "pk_test_ohzQrUWRnTkCLD1cqMeudyjX"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "publicKey", with: row.value ?? "pk_test_ohzQrUWRnTkCLD1cqMeudyjX")
            }
        }
        <<< TextRow("gateway.merchantId"){ row in
            row.title = "Merchant ID"
            row.placeholder = "Enter merchant ID"
            row.value = (config?["gateway"] as? [String: Any])?["merchantId"] as? String ?? ""
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "merchantId", with: row.value ?? "")
            }
        }
        
        // Customer section
        form +++ Section("Customer")
        <<< TextRow("customer.firstName"){ row in
            row.title = "First Name"
            row.placeholder = "Enter first name"
            row.value = (config?["customer"] as? [String: Any])?["firstName"] as? String ?? "Android"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "firstName", with: row.value ?? "Android")
            }
        }
        <<< TextRow("customer.lastName"){ row in
            row.title = "Last Name"
            row.placeholder = "Enter last name"
            row.value = (config?["customer"] as? [String: Any])?["lastName"] as? String ?? "Test"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "lastName", with: row.value ?? "Test")
            }
        }
        <<< TextRow("customer.email"){ row in
            row.title = "Email"
            row.placeholder = "Enter email"
            row.value = (config?["customer"] as? [String: Any])?["email"] as? String ?? "example@gmail.com"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "email", with: row.value ?? "example@gmail.com")
            }
        }
        <<< TextRow("customer.phone.countryCode"){ row in
            row.title = "Phone Country Code"
            row.placeholder = "Enter country code"
            row.value = ((config?["customer"] as? [String: Any])?["phone"] as? [String: Any])?["countryCode"] as? String ?? "965"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "countryCode", with: row.value ?? "965")
            }
        }
        <<< TextRow("customer.phone.number"){ row in
            row.title = "Phone Number"
            row.placeholder = "Enter phone number"
            row.value = ((config?["customer"] as? [String: Any])?["phone"] as? [String: Any])?["number"] as? String ?? "55567890"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "number", with: row.value ?? "55567890")
            }
        }
        
        // Transaction section
        form +++ Section("Transaction")
        <<< SegmentedRow<String>("transaction.mode"){ row in
            row.title = "Transaction Mode"
            row.options = ["charge", "authorize"]
            row.value = (config?["transaction"] as? [String: Any])?["mode"] as? String ?? "charge"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "mode", with: row.value ?? "charge")
            }
        }
        <<< TextRow("transaction.charge.saveCard"){ row in
            row.title = "Save Card"
            row.placeholder = "true/false"
            row.value = String(describing: ((config?["transaction"] as? [String: Any])?["charge"] as? [String: Any])?["saveCard"] as? Bool ?? true)
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "saveCard", with: (row.value ?? "true") == "true")
            }
        }
        <<< TextRow("transaction.charge.threeDSecure"){ row in
            row.title = "3D Secure"
            row.placeholder = "true/false"
            row.value = String(describing: ((config?["transaction"] as? [String: Any])?["charge"] as? [String: Any])?["threeDSecure"] as? Bool ?? true)
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "threeDSecure", with: (row.value ?? "true") == "true")
            }
        }
        <<< TextRow("transaction.charge.redirect.url"){ row in
            row.title = "Redirect URL"
            row.placeholder = "Enter redirect URL"
            row.value = (((config?["transaction"] as? [String: Any])?["charge"] as? [String: Any])?["redirect"] as? [String: Any])?["url"] as? String ?? "https://demo.staging.tap.company/v2/sdk/checkout"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "url", with: row.value ?? "https://demo.staging.tap.company/v2/sdk/checkout")
            }
        }
        
        // Order section
        form +++ Section("Order")
        <<< TextRow("order.id"){ row in
            row.title = "Order ID"
            row.placeholder = "Enter order ID"
            row.value = (config?["order"] as? [String: Any])?["id"] as? String ?? ""
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "id", with: row.value ?? "")
            }
        }
        <<< TextRow("order.currency"){ row in
            row.title = "Order Currency"
            row.placeholder = "Enter currency"
            row.value = (config?["order"] as? [String: Any])?["currency"] as? String ?? "KWD"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "currency", with: row.value ?? "KWD")
            }
        }
        <<< TextRow("order.amount"){ row in
            row.title = "Order Amount"
            row.placeholder = "Enter amount"
            row.value = (config?["order"] as? [String: Any])?["amount"] as? String ?? "5"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "amount", with: row.value ?? "5")
            }
        }
        
        // Card Options section
        form +++ Section("Card Options")
        <<< SwitchRow("cardOptions.showBrands"){ row in
            row.title = "Show Brands"
            row.value = (config?["cardOptions"] as? [String: Any])?["showBrands"] as? Bool ?? true
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "showBrands", with: row.value ?? true)
            }
        }
        <<< SwitchRow("cardOptions.showLoadingState"){ row in
            row.title = "Show Loading State"
            row.value = (config?["cardOptions"] as? [String: Any])?["showLoadingState"] as? Bool ?? false
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "showLoadingState", with: row.value ?? false)
            }
        }
        <<< SwitchRow("cardOptions.collectHolderName"){ row in
            row.title = "Collect Holder Name"
            row.value = (config?["cardOptions"] as? [String: Any])?["collectHolderName"] as? Bool ?? true
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "collectHolderName", with: row.value ?? true)
            }
        }
        <<< TextRow("cardOptions.preLoadCardName"){ row in
            row.title = "Pre-Load Card Name"
            row.placeholder = "Enter card name"
            row.value = (config?["cardOptions"] as? [String: Any])?["preLoadCardName"] as? String ?? ""
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "preLoadCardName", with: row.value ?? "")
            }
        }
        <<< SwitchRow("cardOptions.cardNameEditable"){ row in
            row.title = "Card Name Editable"
            row.value = (config?["cardOptions"] as? [String: Any])?["cardNameEditable"] as? Bool ?? true
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "cardNameEditable", with: row.value ?? true)
            }
        }
        <<< ActionSheetRow<String>("cardOptions.cardFundingSource"){ row in
            row.title = "Card Funding Source"
            row.options = ["all", "credit", "debit"]
            row.value = (config?["cardOptions"] as? [String: Any])?["cardFundingSource"] as? String ?? "all"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "cardFundingSource", with: row.value ?? "all")
            }
        }
        <<< ActionSheetRow<String>("cardOptions.saveCardOption"){ row in
            row.title = "Save Card Option"
            row.options = ["all", "none", "tap", "merchant"]
            row.value = (config?["cardOptions"] as? [String: Any])?["saveCardOption"] as? String ?? "all"
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "saveCardOption", with: row.value ?? "all")
            }
        }
        <<< SwitchRow("cardOptions.forceLtr"){ row in
            row.title = "Force LTR"
            row.value = (config?["cardOptions"] as? [String: Any])?["forceLtr"] as? Bool ?? false
            row.onChange { row in
                self.config?.updateAllOccurrences(ofKey: "forceLtr", with: row.value ?? false)
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let configuration = config {
            print("Saving configuration: \(configuration)")
            delegate?.checkoutSettingsViewControllerDidSave(configuration)
        }
    }
    
    static func createMultiSelectController(
        title: String,
        options: [String],
        initialSelections: [String],
        onComplete: @escaping ([String]) -> Void
    ) -> UIViewController {
        let multiSelectVC = FormViewController()
        multiSelectVC.title = title
        
        var selectedItems = initialSelections
        
        multiSelectVC.form +++ Section()
        
        for option in options {
            multiSelectVC.form.last! <<< CheckRow(option) { row in
                row.title = option
                row.value = initialSelections.contains(option)
                row.onChange { row in
                    if let isSelected = row.value, isSelected {
                        if !selectedItems.contains(option) {
                            selectedItems.append(option)
                        }
                    } else {
                        selectedItems.removeAll { $0 == option }
                    }
                }
            }
        }
        
        multiSelectVC.form +++ Section()
        <<< ButtonRow() { row in
            row.title = "Done"
            row.onCellSelection { _, _ in
                onComplete(selectedItems)
                multiSelectVC.navigationController?.popViewController(animated: true)
            }
        }
        
        return multiSelectVC
    }
}

extension Dictionary where Key == String, Value == Any {
    
    /**
     Recursively updates all occurrences of a specific key with a new value throughout the dictionary and its nested structures.
     
     - Parameters:
     - key: The key to search for and update
     - value: The new value to set for the matching keys
     
     - Returns: A new dictionary with the updated values
     */
    mutating func updateAllOccurrences<T>(ofKey targetKey: String, with newValue: T) {
        for (key, value) in self {
            if key == targetKey {
                self[key] = newValue
            } else if var nestedDict = value as? [String: Any] {
                nestedDict.updateAllOccurrences(ofKey: targetKey, with: newValue)
                self[key] = nestedDict
            } else if var nestedArray = value as? [[String: Any]] {
                for i in 0..<nestedArray.count {
                    var mutableDict = nestedArray[i]
                    mutableDict.updateAllOccurrences(ofKey: targetKey, with: newValue)
                    nestedArray[i] = mutableDict
                }
                self[key] = nestedArray
            } else if var nestedAnyArray = value as? [Any] {
                // Handle arrays of mixed types
                for i in 0..<nestedAnyArray.count {
                    if var nestedDict = nestedAnyArray[i] as? [String: Any] {
                        nestedDict.updateAllOccurrences(ofKey: targetKey, with: newValue)
                        nestedAnyArray[i] = nestedDict
                    }
                }
                self[key] = nestedAnyArray
            }
        }
    }
    
    
    /**
     Creates a new dictionary with all occurrences of a specific key updated with a new value.
     
     - Parameters:
     - key: The key to search for and update
     - value: The new value to set for the matching keys
     
     - Returns: A new dictionary with the updated values
     */
    func updatingAllOccurrences<T>(ofKey targetKey: String, with newValue: T) -> [String: Any] {
        var copy = self
        copy.updateAllOccurrences(ofKey: targetKey, with: newValue)
        return copy
    }
}
extension CheckoutSettingsViewController {
    static let supportedPaymentMethods: [String] = [
        "VISA",
        "MASTERCARD",
        "MEEZA",
        "MADA",
        "KNET",
        "GOOGLE_PAY",
        "FAWRY",
        "CAREEMPAY",
        "BENEFITPAY",
        "BENEFIT",
        "OMANNET",
        "PAYPAL",
        "POST_PAY",
        "NAPS",
        "STC_PAY",
        "TABBY"
    ]
    
    
    static let supportedCurrencies: [String] = [
        "KWD",
        "BHD",
        "SAR",
        "AED",
        "OMR",
        "EGP",
        "GBP",
        "USD",
        "EUR"
    ]
    
    static let supportedCountries: [String] =   [
        "AF",
        "AL",
        "DZ",
        "AS",
        "AD",
        "AO",
        "AI",
        "AQ",
        "AG",
        "AR",
        "AM",
        "AW",
        "AU",
        "AT",
        "AZ",
        "BS",
        "BH",
        "BD",
        "BB",
        "BY",
        "BE",
        "BZ",
        "BJ",
        "BM",
        "BT",
        "BO",
        "BQ",
        "BA",
        "BW",
        "BV",
        "BR",
        "IO",
        "BN",
        "BG",
        "BF",
        "BI",
        "CV",
        "KH",
        "CM",
        "KY",
        "CA",
        "CF",
        "TD",
        "CL",
        "CN",
        "CX",
        "CC",
        "CO",
        "KM",
        "CD",
        "CG",
        "CK",
        "CR",
        "HR",
        "CU",
        "CW",
        "CY",
        "CZ",
        "CI",
        "DK",
        "DJ",
        "DM",
        "DO",
        "EC",
        "EG",
        "SV",
        "GQ",
        "ER",
        "EE",
        "SZ",
        "ET",
        "FK",
        "FO",
        "FJ",
        "FI",
        "FR",
        "GF",
        "PF",
        "TF",
        "GA",
        "GM",
        "GE",
        "DE",
        "GH",
        "GI",
        "GR",
        "GL",
        "GD",
        "GP",
        "GU",
        "GT",
        "GG",
        "GN",
        "GW",
        "GY",
        "HT",
        "HM",
        "VA",
        "HN",
        "HK",
        "HU",
        "IS",
        "IN",
        "ID",
        "IR",
        "IQ",
        "IE",
        "IM",
        "IL",
        "IT",
        "JM",
        "JP",
        "JE",
        "JO",
        "KZ",
        "KE",
        "KI",
        "KP",
        "KR",
        "KW",
        "KG",
        "LA",
        "LV",
        "LB",
        "LS",
        "LR",
        "LY",
        "LT",
        "LI",
        "LU",
        "MO",
        "MG",
        "MW",
        "MY",
        "MV",
        "ML",
        "MT",
        "MH",
        "MQ",
        "MR",
        "MU",
        "YT",
        "MX",
        "FM",
        "MD",
        "MC",
        "MN",
        "ME",
        "MS",
        "MA",
        "MZ",
        "MM",
        "NA",
        "NR",
        "NP",
        "NL",
        "NC",
        "NZ"
    ]
    
}
