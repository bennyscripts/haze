//
//  GeoDatabaseManager.swift
//  IpInfo
//
//  Created by Ben on 11/07/2026.
//


import Foundation

class GeoDatabaseManager {

    static let shared = GeoDatabaseManager()

    private let folderURL: URL

    let cityURL: URL
    let asnURL: URL

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        folderURL = appSupport
            .appendingPathComponent("IPInfo")

        cityURL = folderURL
            .appendingPathComponent("GeoLite2-City.mmdb")

        asnURL = folderURL
            .appendingPathComponent("GeoLite2-ASN.mmdb")

        try? FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )
    }


    func databasesExist() -> Bool {
        FileManager.default.fileExists(atPath: cityURL.path) &&
        FileManager.default.fileExists(atPath: asnURL.path)
    }
    
    func downloadDatabase(
        from urlString: String,
        to destination: URL,
        completion: @escaping (Bool) -> Void
    ) {

        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        URLSession.shared.downloadTask(with: url) { tempURL, _, error in

            guard let tempURL = tempURL,
                  error == nil else {
                completion(false)
                return
            }


            do {
                if FileManager.default.fileExists(
                    atPath: destination.path
                ) {
                    try FileManager.default.removeItem(
                        at: destination
                    )
                }

                try FileManager.default.moveItem(
                    at: tempURL,
                    to: destination
                )

                completion(true)

            } catch {
                print(error)
                completion(false)
            }

        }.resume()
    }
    
    func updateDatabases(completion: @escaping (Bool) -> Void) {

        let group = DispatchGroup()

        var success = true

        group.enter()
        downloadDatabase(
            from: "https://git.io/GeoLite2-City.mmdb",
            to: cityURL
        ) { result in
            success = success && result
            group.leave()
        }


        group.enter()
        downloadDatabase(
            from: "https://git.io/GeoLite2-ASN.mmdb",
            to: asnURL
        ) { result in
            success = success && result
            group.leave()
        }


        group.notify(queue: .main) {

            if success {
                UserDefaults.standard.set(
                    Date(),
                    forKey: "geoDBLastUpdate"
                )
            }

            completion(success)
        }
    }
    
    func shouldUpdate() -> Bool {
        guard let lastUpdate = UserDefaults.standard.object(
            forKey: "geoDBLastUpdate"
        ) as? Date else {
            return true
        }

        let thirtyDays: TimeInterval = 60 * 60 * 24 * 30

        return Date().timeIntervalSince(lastUpdate) > thirtyDays
    }
}
