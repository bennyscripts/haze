import SwiftUI

struct MenuView: View {
    @ObservedObject var appDelegate: AppDelegate
    
    @State private var showData: Bool = false
    @State private var ipText: String = ""
    @State private var ip: IP?
    
    func lookupIP() {
        if ipText == "" {
            return
        }
        
        appDelegate.geoIP?.getInfo(ipAddress: ipText) { response in
            if let response = response {
                DispatchQueue.main.async {
                    self.showData = true
                    self.ip = response
                    self.ipText = response.ip
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let window = NSApp.keyWindow {
                            window.setContentSize(
                                window.contentView?.fittingSize ?? window.frame.size
                            )
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("IP Address...", text: $ipText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {lookupIP()}
                
                Button("Lookup", action: lookupIP)
            }
//            .padding(.bottom, 10)
            
            Divider()
                .padding(.bottom, 0)
                .padding(.top, 10)
                .padding(.horizontal)
                .frame(width: 380.0)
            
            if showData {
                VStack {
                    if let ip = self.ip, ip.hasData {
                        LocationSection(ip: ip)
                        OtherSection(ip: ip)
                    } else {
                        Section {
                            Cell(
                                leading: "Couldn't find any information for this IP address",
                                trailing: ""
                            )
                        }.insetGroupedStyle(header: "IP Info")
                    }
                }
            } else {
                VStack {
                    Section {
                        Cell(leading: "Lookup an IP to see information here", trailing: "")
                    }.insetGroupedStyle(header: "IP Info")
                }
            }
            
//            Divider()
//                .padding(.bottom, 10)
//                .padding(.top, 10)
//                .padding(.horizontal)
//                .frame(width: 380.0)
            
            if showData {
                HStack {
                    Spacer()
                    Button("Reset", action: {
                        self.showData = false
                        self.ipText = ""
                    })
                    
                    Button("Copy", action: {
                        let copyText = """
    Location
    --------
    - Country: \(self.ip!.country)
    - City: \(self.ip!.city)
    - Region: \(self.ip!.region)
    - Postal: \(self.ip!.postal)
    - Latitude: \(self.ip!.latitude)
    - Longitude: \(self.ip!.longitude)
    
    Other
    -----
    - Organisation: \(self.ip!.org)
    - ASN: \(self.ip!.asn)
    - Timezone: \(self.ip!.timezone)
    """
                        
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(copyText, forType: .string)
                    })
                    
                    if self.ip!.hasValidCoordinates && self.ip!.hasData {
                        Button("Open in Maps") {
                            let url = URL(
                                string: "https://maps.apple.com/?ll=\(self.ip!.latitude),\(self.ip!.longitude)"
                            )

                            if let url {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .frame(width: 380)
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(appDelegate: AppDelegate())
    }
}

struct Cell: View {
    var leading: String
    var trailing: String
    
    var body: some View {
        HStack {
            Text(leading)
            Spacer()
            Text(trailing).foregroundColor(.secondary)
        }
        .padding(.vertical, -5)
    }
}

struct LocationSection: View {
    let ip: IP

    var body: some View {
        Section {
            if ip.country_name != "Undefined" {
                Cell(leading: "Country", trailing: "\(ip.country_name) (\(ip.country))")
            }

            if ip.city != "Undefined" {
                Cell(leading: "City", trailing: ip.city)
            }

            if ip.region != "Undefined" {
                Cell(leading: "Region", trailing: "\(ip.region) (\(ip.region_code))")
            }

            if ip.postal != "Undefined" {
                Cell(leading: "Postal", trailing: ip.postal)
            }

            if ip.latitude != 0.0 {
                Cell(leading: "Latitude", trailing: String(ip.latitude))
            }

            if ip.longitude != 0.0 {
                Cell(leading: "Longitude", trailing: String(ip.longitude))
            }

        }.insetGroupedStyle(header: "Location")
    }
}


struct OtherSection: View {
    let ip: IP

    var body: some View {
        Section {
            if ip.org != "Undefined" {
                Cell(leading: "Organisation", trailing: ip.org)
            }

            if ip.asn != "Undefined" {
                Cell(leading: "ASN", trailing: ip.asn)
            }

            if ip.timezone != "Undefined" {
                Cell(leading: "Timezone", trailing: ip.timezone)
            }

        }.insetGroupedStyle(header: "Other")
    }
}

extension View {
    func insetGroupedStyle(header: String) -> some View {
        return GroupBox(label: Text(header.uppercased()).font(.headline).padding(.top).padding(.bottom, 6)) {
            VStack() {
                self.padding(.vertical, 3)
            }.padding(.horizontal).padding(.vertical)
        }
    }
}
