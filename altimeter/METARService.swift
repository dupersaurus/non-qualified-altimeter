//
//  METARService.swift
//  altimeter
//
//  Created by Jason DuPertuis on 2/6/19.
//  Copyright © 2019 jdp. All rights reserved.
//

import Foundation

struct METAR {
    let raw: String?
    let station: String?
    let position: (lat: Double?, long: Double?)
    let temperature: Double?
    let dewPoint: Double?
    let windDirection: Int?
    let windSpeed: Int?
    let visibility: Double?
    let altimeter: Int?
    let elevation: Double?
    
    init(xml: XML.Accessor) {
        raw = xml.raw_text.text
        station = xml.station.text
        position = (lat: xml.latitude.double, long: xml.longitude.double)
        temperature = xml.temp_c.double
        dewPoint = xml.dewpoint_c.double
        windDirection = xml.wind_dir_degrees.int
        windSpeed = xml.wind_speed_kt.int
        visibility = xml.visibility_statute_mi.double
        altimeter = xml.altim_in_hg.double != nil ? Int(round(xml.altim_in_hg.double ?? 0 * 100)) : nil
        elevation = xml.elevation_m.double
    }
}

class METARService {
    
    func getNearby(callback: @escaping ([METAR]) -> Void) {
        AWSRequest(distance: 20, longitude: -117.27, latitude: 32.82) {
            data in
            
            var metars = [METAR]()
            
            if let xmlMETARs = data.METAR.all {
                for xml in xmlMETARs {
                    
                    let accessor = XML.Accessor(xml)
                    metars.append(METAR(xml: accessor))
                }
            }
            
            callback(metars)
        }
    }
    
    /// make a request to Aviation Weather Service api
    private func AWSRequest(distance: Int, longitude: Double, latitude: Double, callback: @escaping (XML.Accessor) -> Void) {
        let query = "radialDistance=\(distance);\(longitude),\(latitude)&hoursBeforeNow=1"
        
        let url = URL(string: "https://www.aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&\(query)")!
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let body = String(data: data, encoding: .utf8) {
                let xml = try! XML.parse(body)
                callback(xml.response.data)
            }
        }
        
        task.resume()
    }
}
