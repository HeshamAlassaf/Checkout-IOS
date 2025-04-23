//
//  CheckoutViewController.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import UIKit
import SnapKit
import WebKit
import SharedDataModels_iOS
import CoreTelephony
import SwiftEntryKit

class CheckoutViewController: UIViewController {
    
    internal let configurations: [String: Any]
    internal let results: CheckoutSDKResults
    internal var webView: WKWebView?
    internal var detectedIP:String = ""
    
    
    // Add top and bottom safe area cover views
    private let topSafeAreaCoverView = UIView()
    private let bottomSafeAreaCoverView = UIView()
    
    internal static let cdnUrl:String = "https://tap-sdks.b-cdn.net/mobile/checkout/base_url.json"
    
    internal static var tabCheckoutConfigUrl: String = "https://mw-sdk.dev.tap.company/v2/"
    internal static var tabCheckoutUrl: String = "https://mw-sdk.dev.tap.company/v2/"
    internal static var sandboxKey:String = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8AX++RtxPZFtns4XzXFlDIxPB
h0umN4qRXZaKDIlb6a3MknaB7psJWmf2l+e4Cfh9b5tey/+rZqpQ065eXTZfGCAu
BLt+fYLQBhLfjRpk8S6hlIzc1Kdjg65uqzMwcTd0p7I4KLwHk1I0oXzuEu53fU1L
SZhWp4Mnd6wjVgXAsQIDAQAB
-----END PUBLIC KEY-----
"""
    internal static var productionKey:String = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8AX++RtxPZFtns4XzXFlDIxPB
h0umN4qRXZaKDIlb6a3MknaB7psJWmf2l+e4Cfh9b5tey/+rZqpQ065eXTZfGCAu
BLt+fYLQBhLfjRpk8S6hlIzc1Kdjg65uqzMwcTd0p7I4KLwHk1I0oXzuEu53fU1L
SZhWp4Mnd6wjVgXAsQIDAQAB
-----END PUBLIC KEY-----
"""
    internal var tabCheckoutConfig :String = "https://checkout.dev.tap.company/"
   
    private var isSandbox:Bool  {
        let gatewayConfig = configurations["gateway"] as? [String:Any]
        let key = gatewayConfig?["publicKey"] as? String ?? ""
        if key.contains("test") {
            return true
        }else {
            return false
        }
    }
    
    private var headersEncryptionPublicKey: String {
        if isSandbox {
            return CheckoutViewController.sandboxKey
        }else{
            return CheckoutViewController.productionKey
        }
    }
    
    init(configurations: [String: Any], results: CheckoutSDKResults) {
        self.configurations = configurations
        self.results = results
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSafeAreaCoverViews()
        setupWebView()
        setupConstraints()
        getIP()
        getCDNURL()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update safe area cover views when layout changes
        updateSafeAreaCoverViews()
    }
    
    // Setup blue views to cover safe area
    private func setupSafeAreaCoverViews() {
        // Configure top safe area cover view
        topSafeAreaCoverView.backgroundColor = .clear
        view.addSubview(topSafeAreaCoverView)
        topSafeAreaCoverView.isHidden = true
        
        // Configure bottom safe area cover view
        bottomSafeAreaCoverView.backgroundColor =  .clear
        view.addSubview(bottomSafeAreaCoverView)
        bottomSafeAreaCoverView.isHidden = true
    }
    
    // Update safe area cover views based on current safe area insets
    private func updateSafeAreaCoverViews() {
        // Update top safe area cover view
        topSafeAreaCoverView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        // Update bottom safe area cover view
        bottomSafeAreaCoverView.snp.remakeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    
    
    /// Fetches the IP of the device
    internal func getIP() {
        let url = URL(string: "https://geolocation-db.com/json/")!
        let task = URLSession.shared.dataTask(with: url) {data, response, error in
            guard let data = data,
                  error == nil,
                  let jsonIP:[String:Any] = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any],
                  let ipString:String = jsonIP["IPv4"] as? String else { return }
            
            self.detectedIP = ipString
        }
        task.resume()
    }
    
    internal func passIP() {
        webView?.evaluateJavaScript("window.setIP('\(detectedIP)')")
    }
    
    func getCDNURL() {
        if let url = URL(string: "https://tap-sdks.b-cdn.net/mobile/checkout/base_url.json") {
            var cdnRequest = URLRequest(url: url)
            cdnRequest.timeoutInterval = 2
            cdnRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            URLSession.shared.dataTask(with: cdnRequest) { data, response, error in
                self.setLoadedDataFromCDN(data: data)
                // we need to update the intent with the sdk info
                self.getCheckoutSDkConfig(configDict: self.configurations)
            }.resume()
        }else{
            // Use the default embedded values as a fallback of all we need to update the intent with the sdk info
            self.getCheckoutSDkConfig(configDict: configurations)
        }
    }
    
    internal func setLoadedDataFromCDN(data: Data?) {
        if let data = data {
            do {
                if let cdnResponse:[String:String] = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                   let cdnBaseUrlString:String = cdnResponse["baseURL"], cdnBaseUrlString != "",
                   let cdnBaseUrl:URL = URL(string: cdnBaseUrlString),
                   let sandboxEncryptionKey:String = cdnResponse["testEncKey"],
                   let productionEncryptionKey:String = cdnResponse["prodEncKey"] {
                    CheckoutViewController.sandboxKey = sandboxEncryptionKey
                    CheckoutViewController.productionKey = productionEncryptionKey
                    CheckoutViewController.tabCheckoutConfigUrl = cdnBaseUrlString
                }
            } catch {}
        }
    }
    
    internal func getCheckoutSDkConfig(configDict: [String : Any]) {
        if let url = URL(string: "\(CheckoutViewController.tabCheckoutConfigUrl)checkout/config") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            //            let headers: [String: Any] = generateApplicationHeader()
            var updatedConfigurations = self.configurations
            updatedConfigurations["headers"] = generateApplicationHeader()
            //            let mdnHeader = headers["mdnHeader"] as? String ?? ""
            //            let applicationHeader = headers["applicationHeader"] as? String ?? ""
            //            request.setValue(applicationHeader, forHTTPHeaderField: "application")
            //            request.setValue(mdnHeader, forHTTPHeaderField: "mdn")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: configDict, options: [])
                // Create a URLSession task to make the request
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error: \(error)")
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("Invalid response")
                        return
                    }
                    
                    print("Status code: \(httpResponse.statusCode)")
                    
                    if let data = data {
                        do {
                            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                print("Response: \(jsonResponse)")
                                if let redirectUrlString = jsonResponse["redirect_url"] as? String {
                                    CheckoutViewController.tabCheckoutUrl = self.transformURlFromConfig(redirectUrlString)
                                    self.postLoadingFromCDN()
                                }
                            }
                        } catch {
                            print("Error parsing response: \(error)")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("Response string: \(responseString)")
                            }
                        }
                    }
                }.resume()
                
            } catch {
                print("Error creating request body: \(error)")
            }
        }
        
    }
    
    internal func postLoadingFromCDN() {
        do {
            print("CheckoutViewController.tabCheckoutUrl: \(CheckoutViewController.tabCheckoutUrl)")
            let url = URL(string: CheckoutViewController.tabCheckoutUrl)!
            try openUrl(url: url)
        }
        catch {
            //            self.delegate?.onError?(data: "{error:\(error.localizedDescription)}")
        }
    }
    
    private func openUrl(url: URL?) {
        // Store it for further usages
        //        currentlyLoadedCardConfigurations = url
        // instruct the web view to load the needed url
        var request = URLRequest(url: url!)
        request.setValue(TapApplicationPlistInfo.shared.bundleIdentifier ?? "", forHTTPHeaderField: "referer")
        DispatchQueue.main.async {
            self.webView?.navigationDelegate = self
            self.webView?.load(request)
        }
    }
    
    func transformURlFromConfig(_ configUrl: String) -> String {
        var transformedUrl = configUrl
        
        // Replace either of the possible domains
        if transformedUrl.contains("https://checkout.dev.tap.company") {
            transformedUrl = transformedUrl.replacingOccurrences(
                of: "https://checkout.dev.tap.company",
                with: "https://tap-checkout-wrapper.netlify.app"
            )
        } else if transformedUrl.contains("https://checkout.staging.tap.company") {
            transformedUrl = transformedUrl.replacingOccurrences(
                of: "https://checkout.staging.tap.company",
                with: "https://tap-checkout-wrapper.netlify.app"
            )
        }
        
        // Add platform parameter if it doesn't already have one
        if !transformedUrl.contains("platform=") {
            // Check if we need to add a ? or & before the parameter
            if transformedUrl.contains("?") {
                transformedUrl += "&platform=mobile"
            } else {
                transformedUrl += "?platform=mobile"
            }
        }
        
        return transformedUrl
    }
}

internal extension CheckoutViewController {
    private func setupWebView() {
        // Creates needed configuration for the web view
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        // Let us make sure it is of a clear background and opaque, not to interfer with the merchant's app background
        webView?.isOpaque = false
        webView?.backgroundColor = UIColor.clear
        webView?.scrollView.backgroundColor = UIColor.clear
        webView?.scrollView.bounces = false
        webView?.isHidden = false
        // Let us add it to the view
        self.view.backgroundColor = UIColor.clear
        self.view.addSubview(webView!)
    }
    
    private func setupConstraints() {
        // Defensive coding
        guard let webView = self.webView else {
            return
        }
        
        
        webView.snp.makeConstraints{ make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            
        }
    }
}

extension CheckoutViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("navigationAction: \(webView.url?.absoluteString ?? "unknown")")
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
          var action: WKNavigationActionPolicy?
          
          defer {
              decisionHandler(action ?? .allow)
          }
          
          guard let url = navigationAction.request.url else { return }
          
          if url.absoluteString.hasPrefix("tapcheckoutsdk") {
              print("navigationAction", url.absoluteString)
              action = .cancel
          }else{
              print("navigationAction", url.absoluteString)
          }
          
          switch url.absoluteString {
          case _ where url.absoluteString.contains("onReady"):
              results.onReady()
              break
          case _ where url.absoluteString.contains("onFocus"):
//              delegate?.onFocus?()
              break
          case _ where url.absoluteString.contains("onError"):
              handleError(data: tap_extractDataFromUrl(url.absoluteURL))
              break
          case _ where url.absoluteString.contains("onSuccess"):
//              delegate?.onSuccess?(data: tap_extractDataFromUrl(url.absoluteURL))
              break
          case _ where url.absoluteString.contains("onRedirectUrl"):
              handleRedirection(data: tap_extractDataFromUrl(url.absoluteURL))
              break
          default:
              break
          }
      }
    
    
    internal func handleError(data:String) {
        print(data)
    }
    
    internal func handleRedirection(data: String) {
        print(data)
        // let us make sure we have the data we need to start such a process
        guard let redirectionData: RedirectionData = try? RedirectionData(data),
              let _:String = redirectionData.url,
              let _:String = redirectionData.redirectionUrl?.url else {
            // This means, there is such an error from the integration with web sdk
//            delegate?.onError?(data: "Failed to start redirect process")
            return
        }
        
        // This means we are ok to start the authentication process
        let redirectView:RedirectionView = .init(frame: .zero)
        // Set to web view the needed urls
        redirectView.redirectionData = redirectionData
        // Set the selected card locale for correct semantic rendering
        redirectView.selectedLocale = "en"
        // Set to web view what should it when the process is canceled by the user
        redirectView.threeDSCanceled = {
//            // reload the card data
//            self.openUrl(url: self.currentlyLoadedCardConfigurations)
//            // inform the merchant
//            self.delegate?.onError?(data: "Payer canceled three ds process")
//            // dismiss the threeds page
//            SwiftEntryKit.dismiss()
        }
        // Hide or show the powered by tap based on coming parameter
        redirectView.poweredByTapView.isHidden = !(redirectionData.powered ?? true)
        // Set to web view what should it when the process is completed by the user
        redirectView.redirectionReached = { redirectionUrl in
            SwiftEntryKit.dismiss {
                DispatchQueue.main.async {
                    self.passRedirectionDataToSDK(rediectionUrl: redirectionUrl)
                }
            }
        }
        // Set to web view what should it do when the content is loaded in the background
        redirectView.idleForWhile = {
            DispatchQueue.main.async {
                SwiftEntryKit.display(entry: redirectView, using: redirectView.swiftEntryAttributes())
            }
        }
        // Tell it to start rendering 3ds content in background
        redirectView.startLoading()
        
    }
    
    /// Tells the web sdk the process is finished with the data from backend
    /// - Parameter rediectionUrl: The url with the needed data coming from back end at the end of the currently running process
    internal func passRedirectionDataToSDK(rediectionUrl:String) {
        print("rediectionUrl: \(rediectionUrl)")
        webView?.evaluateJavaScript("window.retrieve('\(rediectionUrl)')")
        //generateTapToken()
    }
    
}

internal extension CheckoutViewController {
    
    //MARK: - Network's headers
    /// Generates the mdn & the application required headers
    func generateApplicationHeader() -> [String:String] {
        return [
            Constants.HTTPHeaderKey.application: applicationHeaderValue,
            Constants.HTTPHeaderKey.mdn: Crypter.encrypt(TapApplicationPlistInfo.shared.bundleIdentifier ?? "", using: headersEncryptionPublicKey) ?? ""
        ]
    }
    
    
    /// HTTP headers that contains the device and app info
    private var applicationHeaderValue: String {
        
        var applicationDetails = applicationStaticDetails()
        
        let localeIdentifier = "en"
        
        applicationDetails[Constants.HTTPHeaderValueKey.appLocale] = localeIdentifier
        
        
        let result = (applicationDetails.map { "\($0.key)=\($0.value)" }).joined(separator: "|")
        
        return result
    }
    
    /// A computed variable that generates at access time the required static headers by the server.
    func applicationStaticDetails() -> [String: String] {
        
        /*guard let bundleID = TapApplicationPlistInfo.shared.bundleIdentifier, !bundleID.isEmpty else {
         
         fatalError("Application must have bundle identifier in order to use goSellSDK.")
         }*/
        
        let bundleID = TapApplicationPlistInfo.shared.bundleIdentifier ?? ""
        
        let sdkPlistInfo = TapBundlePlistInfo(bundle: Bundle(for: CheckoutViewController.self))
        
        guard let requirerVersion = sdkPlistInfo.shortVersionString, !requirerVersion.isEmpty else {
            
            fatalError("Seems like SDK is not integrated well.")
        }
        let networkInfo = CTTelephonyNetworkInfo()
        let providers = networkInfo.serviceSubscriberCellularProviders
        
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let deviceName = UIDevice.current.name
        let deviceNameFiltered =  deviceName.tap_byRemovingAllCharactersExcept("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789 ()")
        let deviceType = UIDevice.current.model
        let deviceModel = getDeviceCode() ?? ""
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        var simNetWorkName:String? = ""
        var simCountryISO:String? = ""
        
        if providers?.values.count ?? 0 > 0, let carrier:CTCarrier = providers?.values.first {
            simNetWorkName = carrier.carrierName
            simCountryISO = carrier.isoCountryCode
        }
        
        
        let result: [String: String] = [
            Constants.HTTPHeaderValueKey.appID: Crypter.encrypt(bundleID, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirer: Crypter.encrypt(Constants.HTTPHeaderValueKey.requirerValue, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerVersion: Crypter.encrypt(requirerVersion, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerOS: Crypter.encrypt(osName, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerOSVersion: Crypter.encrypt(osVersion, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceName: Crypter.encrypt(deviceNameFiltered, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceType: Crypter.encrypt(deviceType, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceModel: Crypter.encrypt(deviceModel, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerSimNetworkName: Crypter.encrypt(simNetWorkName ?? "", using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerSimCountryIso: Crypter.encrypt(simCountryISO ?? "", using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.deviceID: Crypter.encrypt(deviceID , using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.appType: Crypter.encrypt("app" , using: headersEncryptionPublicKey) ?? ""
        ]
        
        return result
    }
    
    
    /// A constants for the network logs
    struct Constants {
        
        internal static let authenticateParameter = "authenticate"
        
        fileprivate static let timeoutInterval: TimeInterval            = 60.0
        fileprivate static let cachePolicy:     URLRequest.CachePolicy  = .reloadIgnoringCacheData
        
        fileprivate static let successStatusCodes = 200...299
        
        fileprivate struct HTTPHeaderKey {
            
            fileprivate static let authorization            = "Authorization"
            fileprivate static let application              = "application"
            fileprivate static let sessionToken             = "session_token"
            fileprivate static let contentTypeHeaderName    = "Content-Type"
            fileprivate static let token                    = "session"
            fileprivate static let mdn                      = "mdn"
            
            //@available(*, unavailable) private init() { }
        }
        
        fileprivate struct HTTPHeaderValueKey {
            
            fileprivate static let appID                    = "cu"
            fileprivate static let appLocale                = "al"
            fileprivate static let appType                  = "at"
            fileprivate static let deviceID                 = "di"
            fileprivate static let requirer                 = "aid"
            fileprivate static let requirerOS               = "ro"
            fileprivate static let requirerOSVersion        = "rov"
            fileprivate static let requirerValue            = "card-ios"
            fileprivate static let requirerVersion          = "av"
            fileprivate static let requirerDeviceName       = "rn"
            fileprivate static let requirerDeviceType       = "rt"
            fileprivate static let requirerDeviceModel      = "rm"
            fileprivate static let requirerSimNetworkName   = "rsn"
            fileprivate static let requirerSimCountryIso    = "rsc"
            
            fileprivate static let jsonContentTypeHeaderValue   = "application/json"
            
            //@available(*, unavailable) private init() { }
        }
    }
    
    
    func getDeviceCode() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return modelCode
    }
}
