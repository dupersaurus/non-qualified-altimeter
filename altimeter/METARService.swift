//
//  METARService.swift
//  altimeter
//
//  Created by Jason DuPertuis on 2/6/19.
//  Copyright © 2019 jdp. All rights reserved.
//

import Foundation

struct Position {
    let latitude: Double
    let longitude: Double
    
    init(lat: Double, long: Double) {
        latitude = lat
        longitude = long
    }
    
    static func distance(a: Position, b: Position) -> Double {
        let aLatRad = (a.latitude * Double.pi) / 180
        let bLatRad = (b.latitude * Double.pi) / 180
        let longDeltaRad = ((b.longitude - a.longitude) * Double.pi) / 180
        
        //return sqrt(pow(b.longitude - a.longitude, 2) + pow(b.latitude - a.latitude, 2))
        return acos( sin(aLatRad) * sin(bLatRad) + cos(aLatRad) * cos(bLatRad) * cos(longDeltaRad) ) * 3440.277
    }
}

struct METAR {
    let raw: String?
    let station: String
    let time: String
    let position: Position
    let distance: Double
    let qnh: Double
    let temperature: Double?
    let dewPoint: Double?
    let windDirection: Int?
    let windSpeed: Int?
    let visibility: Double?
    let altimeter: Int?
    let elevation: Double?
    
    init(xml: XML.Accessor, origin: Position) {
        raw = xml.raw_text.text
        station = xml.station_id.text!
        time = xml.observation_time.text!
        position = Position(lat: xml.latitude.double ?? 0.0, long: xml.longitude.double ?? 0.0)
        distance = Position.distance(a: origin, b: position)
        qnh = xml.altim_in_hg.double!
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
    
    func getNearby(callback: @escaping ([String: METAR]) -> Void) {
        let position = Position(lat: 35.8480, long: -78.6317)
        
        AWSRequest(distance: 40, longitude: position.longitude, latitude: position.latitude) {
            data in
            
            var metars = [String: METAR]()
            
            if let xmlMETARs = data.METAR.all {
                for xml in xmlMETARs {
                    
                    let accessor = XML.Accessor(xml)
                    let newMETAR = METAR(xml: accessor, origin: position)
                    var isNew = false
                    
                    if let metar = metars[newMETAR.station] {
                        isNew = newMETAR.time > metar.time
                    } else {
                        isNew = true
                    }
                    
                    if isNew {
                        metars[newMETAR.station] = newMETAR
                    }
                }
            }
            
            /*metars.sort {
                return $0.distance < $1.distance
            }*/
            
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
