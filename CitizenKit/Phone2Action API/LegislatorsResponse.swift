//
//  LegislatorsResponse.swift
//  CitizenKit
//
//  Created by Cal Stephens on 2/16/19.
//  Copyright © 2019 Clifford Panos. All rights reserved.
//

import Foundation

struct LegislatorsResponse: Codable {
    let officials: [OfficialResponse]
}

struct OfficialResponse: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let termStart: Date
    let termEnd: Date?
    let party: String
    let photo: String
    let websites: [String]?
    let emails: [String]?
    let officeDetails: OfficeDetailResponse
    let officeLocation: OfficeLocationResponse
    let socials: [SocialResponse]
}

struct OfficeDetailResponse: Codable {
    let position: String
    let state: String?
    let city: String?
    let district: DistrictResponse
    
    var officeLocationString: String? {
        if let state = state, !state.isEmpty {
            if let city = city, !city.isEmpty {
                return "\(city), \(state)"
            } else {
                return state
            }
        } else {
            return nil
        }
    }
}

struct DistrictResponse: Codable {
    let type: DistrictTypeResponse
    let id: String?
    let city: String?
    
    var number: Int? {
        guard let id = id else { return nil }
        return Int(id)
    }
}

struct OfficeLocationResponse: Codable {
    let city: String?
    let state: String?
    
    var string: String? {
        if let state = state, !state.isEmpty {
            if let city = city, !city.isEmpty {
                return "\(city), \(state)"
            } else {
                return state
            }
        } else {
            return nil
        }
    }
}

struct SocialResponse: Codable {
    let identifierType: String
    let identifierValue: String
}

enum DistrictTypeResponse: String, Codable {
    case nationalExecutive = "NATIONAL_EXEC"
    case nationalSenator = "NATIONAL_UPPER"
    case nationalRepresentative = "NATIONAL_LOWER"
    case stateExecutive = "STATE_EXEC"
    case stateSenator = "STATE_UPPER"
    case stateRepresentative = "STATE_LOWER"
    case localExecutive = "LOCAL_EXEC"
    case localOffice = "LOCAL"
}


// MARK: LegislatorsReponse + DecoderProvider

extension LegislatorsResponse: DecoderProvider {
    
    static var preferredDecoder: AnyDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD HH:mm:ss"
        
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
    
}


// MARK: Legislator + LegislatorResponse

extension Legislator {
    
    convenience init(from response: OfficialResponse) {
        
        let position = response.officeDetails.position
        let state = USState.from(response.officeDetails.state ?? "Unknown")
        let office: Legislator.Office
        
        switch response.officeDetails.district.type {
        case .nationalExecutive:
            office = .executive(title: position)
        
        case .nationalSenator:
            office = .senator(for: state)
            
        case .nationalRepresentative:
            office = .houseRepresentative(
                for: state,
                district: response.officeDetails.district.number ?? 0)
            
        case .stateExecutive:
            office = .stateExecutive(title: position, of: state)
            
        case .stateSenator:
            office = .stateSenator(
                of: state,
                district: response.officeDetails.district.number ?? 0)
            
        case .stateRepresentative:
            office = .stateRepresentative(
                of: state,
                district: response.officeDetails.district.number ?? 0)
            
        case .localExecutive, .localOffice:
            office = .localExecutive(
                title: response.officeDetails.position,
                city: response.officeDetails.district.city ?? "Unknown",
                state: state)
        }
        
        let website: URL?
        if let websiteString = response.websites?.first,
            let websiteURL = URL(string: websiteString)
        {
            website = websiteURL
        }
        else {
            website = nil
        }
        
        var partyOverride: Party? = nil
        var imageURLOverride: URL? = nil
        if response.id == 54690 /* London Breed */ {
            partyOverride = .democrat
            imageURLOverride = URL(string: "http://sfcommunityalliance.org/wp-content/uploads/2018/04/oBMVsSAH_400x400.jpg")!
        }
        
        self.init(
            name: "\(response.firstName) \(response.lastName)",
            office: office,
            party: partyOverride ?? Party(rawValue: response.party) ?? .unknown,
            imageURL: imageURLOverride ?? URL(string: response.photo)
                ?? URL(string: "https://t4.ftcdn.net/jpg/02/15/84/43/240_F_215844325_ttX9YiIIyeaR7Ne6EaLLjMAmy4GvPC69.jpg")!,
            website: website,
            email: response.emails?.first,
            officeLocation: response.officeLocation.string
                ?? response.officeDetails.officeLocationString
                ?? "Unknown City",
            termStart: response.termStart,
            termEnd: response.termEnd
        )
        
        for socialResponse in response.socials {
            if let provider = SocialService.Provider(rawValue: socialResponse.identifierType) {
                let existing = self.socialServices.filter({ $0.provider == provider }).count > 0
                if existing { continue }
                self.socialServices.append(SocialService(provider: provider, value: socialResponse.identifierValue))
            }
        }
        
    }
    
}
