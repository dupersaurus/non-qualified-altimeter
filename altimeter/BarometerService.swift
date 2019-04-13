//
//  BarometerService.swift
//  altimeter
//
//  Created by Jason DuPertuis on 2/5/19.
//  Copyright © 2019 jdp. All rights reserved.
//

import Foundation
import CoreMotion

enum BarometerError: Error {
    case notAvailable
}

typealias AltitudeData = (qnh: Int, kpa: Double, inHg: Double, altitude: Double?, pressureAltitude: Double?)

class BarometerService {
    var qnh = 29.92
    var lastKPA = 0.0;
    
    let altimeter = CMAltimeter()
    
    func observeBarometer(listener: @escaping (AltitudeData) -> Void) throws {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            throw BarometerError.notAvailable
        }
        
        
        
        altimeter.startRelativeAltitudeUpdates(to: .main) {
            (data, error) in
            
            if data == nil {
                print("No altimeter data available")
            }
            
            else if error != nil {
                print("\(String(describing: error))")
            }
            
            else {
                DispatchQueue.main.async {
                    if let pressureKPA = data?.pressure.doubleValue {
                        self.lastKPA = pressureKPA
                        listener(self.calculateAltitudeComponents(pressureKPA: pressureKPA))
                    } else {
                        listener((self.qnhToInt(), 101.325, self.kpaToInhg(kpa: 101.325), nil, nil))
                    }
                }
            }
        }
        
        listener(calculateAltitudeComponents(pressureKPA: 101.325))
    }
    
    private func calculateAltitudeComponents(pressureKPA: Double) -> AltitudeData {
        let pressureHg = self.kpaToInhg(kpa: pressureKPA)
        let altitude = self.calculateIndicatedAltitude(inHg: pressureHg)
        let palt = self.calculatePressureAltitude(inHg: pressureHg)
        
        return (qnhToInt(), pressureKPA, pressureHg, altitude, palt)
    }
    
    func setQNH(qnh: Int) -> AltitudeData {
        self.qnh = Double(qnh) * 0.01;
        return calculateAltitudeComponents(pressureKPA: lastKPA)
    }
    
    func setIndicatedPressure(inHg: Int) -> AltitudeData {
        qnh = Double(inHg) / 100;
        self.lastKPA = (qnh / 10) * 33.8639;
        return calculateAltitudeComponents(pressureKPA: lastKPA)
    }
    
    /// indicated altitude is 1000 ft per 1" different in Hg from QNH
    private func calculateIndicatedAltitude(inHg: Double) -> Double {
        return (self.qnh - inHg) * 1000;
    }
    
    /// calculate the pressure altitude
    private func calculatePressureAltitude(inHg: Double) -> Double {
        let mb = inHg * 33.8639;
        return 145366.45 * (1 - pow(mb / 1013.25, 0.190284));
    }
    
    /// convert kilopascals to inches of mercury
    private func kpaToInhg(kpa: Double) -> Double {
        return kpa * 0.295300;
    }
    
    // convert kilopascals to millibars
    private func kpaToMb(kpa: Double) -> Double {
        return kpa * 10;
    }
    
    private func qnhToInt() -> Int {
        return Int(qnh * 100)
    }
}
