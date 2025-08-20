//
//  HTTPPayload.swift
//  IPATool
//
//  Created by Majd Alfhaily on 22.05.21.
//

import Foundation

enum HTTPPayload {
    case xml([String: Any])
    case urlEncoding([String: String])
}
