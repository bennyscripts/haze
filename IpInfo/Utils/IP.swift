import Foundation

struct IP {
    var ip: String = "Undefined"
    var version: String = "Undefined"
    
    var city: String = "Undefined"
    var region: String = "Undefined"
    var region_code: String = "Undefined"
    var country: String = "Undefined"
    var country_name: String = "Undefined"
    var country_code: String = "Undefined"
    
    var postal: String = "Undefined"
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var timezone: String = "Undefined"
    
    var asn: String = "Undefined"
    var org: String = "Undefined"
}

extension IP {
    var dataCount: Int {
        var count = 0
        
        if country_name != "Undefined" { count += 1 }
        if city != "Undefined" { count += 1 }
        if region != "Undefined" { count += 1 }
        if postal != "Undefined" { count += 1 }
        if latitude != 0.0 { count += 1 }
        if longitude != 0.0 { count += 1 }
        if timezone != "Undefined" { count += 1 }
        if asn != "Undefined" { count += 1 }
        if org != "Undefined" { count += 1 }
        
        return count
    }
    
    var hasData: Bool {
        dataCount >= 3
    }
    
    var hasValidCoordinates: Bool {
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180
    }
}
