//
//  InterfaceController.swift
//  altimeter WatchKit Extension
//
//  Created by Jason DuPertuis on 2/5/19.
//  Copyright © 2019 jdp. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController, WKCrownDelegate {

    @IBOutlet weak var qnhDisplay: WKInterfaceLabel!
    @IBOutlet weak var altitudeDisplay: WKInterfaceLabel!
    
    let barometerService = BarometerService()
    var lastQNH = 2992
    
    var cumulativeDelta = 0.0
    let minimumDelta = 0.02
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        crownSequencer.delegate = self
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        crownSequencer.focus()
        
        do {
            try barometerService.observeBarometer() {
                altitude in
                
                self.updateDisplay(data: altitude)
            }
        } catch BarometerError.notAvailable {
            print("Barometer not available")
        } catch {
            print("Unable to run barometer")
        }
    }
    
    override func didAppear() {
        crownSequencer.focus()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateDisplay(data: AltitudeData) {
        self.lastQNH = data.qnh
        self.qnhDisplay.setText(self.inHgToString(inhg: data.qnh))
        self.altitudeDisplay.setText(self.altitudeToString(altitude: data.altitude ?? 0))
    }

    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        cumulativeDelta += rotationalDelta
        
        if abs(cumulativeDelta) < minimumDelta {
            return
        }
        
        cumulativeDelta = 0;
        var amount = 0;
        let absolute = abs(rotationalDelta)
        
        switch absolute {
        case 0..<minimumDelta:
            amount = 1
            
        case minimumDelta..<0.03:
            amount = 2
            
        case 0.03..<0.04:
            amount = Int(absolute * 20.0)
            
        case 0.04..<0.06:
            amount = Int(absolute * 50.0)
            
        default:
            amount = Int(absolute * 100.0)
        }
        
        if rotationalDelta < 0 {
            amount *= -1
        }
        
        let nextQNH = lastQNH + amount;
        updateDisplay(data: barometerService.setQNH(qnh: nextQNH))
    }
    
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?) {
        
    }
    
    func inHgToString(inhg: Int) -> String {
        return "\(inhg / 100).\(inhg % 100)"
    }
    
    func inHgToString(inhg: Double) -> String {
        return "\(Int(inhg)).\(Int(inhg * 100) % 100)"
    }
    
    func altitudeToString(altitude: Double) -> String {
        if (altitude < 0) {
            return "0";
        }
        
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        return formatter.string(for: Int(altitude)) ?? "--"
    }
}
