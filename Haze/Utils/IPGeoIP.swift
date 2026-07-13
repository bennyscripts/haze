//
//  IPGeoIP.swift
//  IpInfo
//
//  Created by Ben on 11/07/2026.
//


import Foundation
import MaxMindDB

class IPGeoIP {

    private let cityDB: GeoIP2
    private let asnDB: GeoIP2

    init?() {
        let cityURL = GeoDatabaseManager.shared.cityURL
        let asnURL = GeoDatabaseManager.shared.asnURL

        guard FileManager.default.fileExists(atPath: cityURL.path),
              FileManager.default.fileExists(atPath: asnURL.path)
        else {
            print("Missing MMDB files")
            return nil
        }
        
        do {
            cityDB = try GeoIP2(databasePath: cityURL.path)
            asnDB = try GeoIP2(databasePath: asnURL.path)
        } catch {
            print("Failed loading databases:", error)
            return nil
        }
    }


    func getInfo(ipAddress: String, completion: @escaping (IP?) -> ()) {

        DispatchQueue.global(qos: .userInitiated).async {

            var response = IP()
            response.ip = ipAddress


            // GeoLite2 City
            do {
                let result = try self.cityDB.lookup(ip: ipAddress)
                let data = result.data

                if let city = data["city"] as? [String: Any],
                   let names = city["names"] as? [String: String] {
                    response.city = names["en"] ?? "Undefined"
                }

                if let country = data["country"] as? [String: Any] {
                    if let names = country["names"] as? [String: String] {
                        response.country_name = names["en"] ?? "Undefined"
                    }

                    response.country =
                        country["iso_code"] as? String ?? "Undefined"
                }

                if let location = data["location"] as? [String: Any] {

                    response.timezone =
                        location["time_zone"] as? String ?? "Undefined"

                    if let latitude = location["latitude"] as? Double {
                        response.latitude = Double(latitude)
                    }

                    if let longitude = location["longitude"] as? Double {
                        response.longitude = Double(longitude)
                    }
                }

                if let subdivisions = data["subdivisions"] as? [[String: Any]],
                   let region = subdivisions.first {

                    if let names = region["names"] as? [String: String] {
                        response.region = names["en"] ?? "Undefined"
                    }

                    response.region_code =
                        region["iso_code"] as? String ?? "Undefined"
                }

                response.postal =
                    (data["postal"] as? [String: Any])?["code"] as? String
                    ?? "Undefined"

            } catch {
                print("City lookup failed:", error)
            }


            // GeoLite2 ASN
            do {
                let result = try self.asnDB.lookup(ip: ipAddress)
                let data = result.data

                if let asn = data["autonomous_system_number"] as? Int {
                    response.asn = "AS\(asn)"
                }

                response.org =
                    data["autonomous_system_organization"] as? String
                    ?? "Undefined"

            } catch {
                print("ASN lookup failed:", error)
            }


            DispatchQueue.main.async {
                completion(response)
            }
        }
    }
}

