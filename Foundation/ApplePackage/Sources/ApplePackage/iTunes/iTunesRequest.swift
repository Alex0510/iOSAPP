//
//  iTunesRequest.swift
//  IPATool
//
//  Created by Majd Alfhaily on 22.05.21.
//

import Foundation

enum iTunesRequest {
    case search(type: EntityType, term: String, limit: Int, offset: Int? = nil, region: String)
    case lookup(type: EntityType, bundleIdentifier: String, region: String)
}

public enum EntityType: String, Codable, CaseIterable, Hashable, Equatable {
    case iPhone
    case iPad
    
    public var systemImage: String {
        switch self {
        case .iPhone:
            return "iphone"
        case .iPad:
            return "ipad"
        }
    }
}

extension EntityType {
    var entityValue: String {
        switch self {
        case .iPhone:
            "software"
        case .iPad:
            "iPadSoftware"
        }
    }
}

extension iTunesRequest: HTTPRequest {
    var method: HTTPMethod {
        .get
    }

    var endpoint: HTTPEndpoint {
        switch self {
        case .lookup:
            iTunesEndpoint.lookup
        case .search:
            iTunesEndpoint.search
        }
    }

    var payload: HTTPPayload? {
        switch self {
        case let .lookup(type, bundleIdentifier, region):
            return HTTPPayload.urlEncoding(["entity": type.entityValue, "bundleId": bundleIdentifier, "limit": "1", "country": region])
        case let .search(type, term, limit, offset, region):
            var params: [String: String] = ["entity": type.entityValue, "term": term, "limit": "\(limit)", "country": region]
            if let offset = offset {
                params["offset"] = "\(offset)"
            }
            return HTTPPayload.urlEncoding(params)
        }
    }
}
