//
//  File.swift
//  CitizenKit
//
//  Created by Cal Stephens on 2/16/19.
//  Copyright © 2019 Clifford Panos. All rights reserved.
//

import Foundation

public enum Phone2Action {
    
    private static let endpointURL = URL(string: "")!
    
    public static func fetchLegislators(for address: String) -> Promise<[Legislator]> {
        let promise = Promise<[Legislator]>()
        
        // build the request query
        var urlComponents = URLComponents(
            string: "https://q4ktfaysw3.execute-api.us-east-1.amazonaws.com/treehacks/legislators")!
        
        urlComponents.queryItems = [URLQueryItem(name: "address",value: address)]
        
        guard let url = urlComponents.url else {
            promise.reject(EncodingError.invalidValue(address,
                EncodingError.Context(codingPath: [], debugDescription: "Invalid address.")))
            return promise
        }
        
        var request = URLRequest(url: url)
        request.setValue("2e1uvo7yeX50ZGHvctPxi8ZWubhggyOydIWvOa5c", forHTTPHeaderField: "X-API-KEY")
        
        // kick off the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                promise.reject(error)
                return
            }
            
            guard let data = data else {
                promise.reject(DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "No data available.")))
                return
            }
            
            do {
                let legislators = try LegislatorsResponse.preferredDecoder.decode(LegislatorsResponse.self, from: data)
                promise.fulfill(legislators.officials.map(Legislator.init(from:)))
            } catch {
                promise.reject(error)
            }
        }.resume()
        
        return promise
    }
    
}
