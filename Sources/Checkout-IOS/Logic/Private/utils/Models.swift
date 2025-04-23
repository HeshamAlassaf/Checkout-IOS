//
//  Models.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import Foundation

struct RedirectionData: Codable {
    /// The redirection URL object containing the URL to redirect to
    var redirectionUrl: RedirectionUrlObject?
    /// The URL for the payment process
    var url: String?
    /// The keyword to identify the redirection
    var keyword: String?
    /// Whether or not to show the powered by tap flag
    var powered: Bool?
    
    /// Nested struct for the redirectionUrl object
    struct RedirectionUrlObject: Codable {
        /// The URL to redirect to
        var url: String?
    }
}

// MARK: RedirectionData convenience initializers and mutators
extension RedirectionData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RedirectionData.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        redirectionUrl: RedirectionUrlObject?? = nil,
        url: String?? = nil,
        keyword: String?? = nil,
        powered: Bool?? = nil
    ) -> RedirectionData {
        return RedirectionData(
            redirectionUrl: redirectionUrl ?? self.redirectionUrl,
            url: url ?? self.url,
            keyword: keyword ?? self.keyword,
            powered: powered ?? self.powered
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders
func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
