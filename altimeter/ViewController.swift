//
//  ViewController.swift
//  altimeter
//
//  Created by Jason DuPertuis on 2/5/19.
//  Copyright © 2019 jdp. All rights reserved.
//

import Foundation
import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var kpaValue: UILabel!
    @IBOutlet weak var inhgValue: UILabel!
    @IBOutlet weak var qnhValue: UILabel!
    @IBOutlet weak var altitudeValue: UILabel!
    @IBOutlet weak var pressureValues: UIPickerView!
    
    let barometerService = BarometerService()
    var pressureValueList: [Int] = []
    var selectedPressureValue = 182;

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        pressureValues.delegate = self
        pressureValues.dataSource = self
        
        var altSetting = 2810
        while altSetting <= 3100 {
            pressureValueList.append(altSetting)
            altSetting += 1;
        }
        
        pressureValues.selectRow(selectedPressureValue, inComponent: 0, animated: false)
        
        do {
            try barometerService.observeBarometer() {
                (data: AltitudeData) in
                
                self.applyAltitudeData(data: data)
            }
        } catch BarometerError.notAvailable {
            print("Barometer not available")
        } catch {
            print("Unable to run barometer")
        }
    }
    
    func applyAltitudeData(data: AltitudeData) {
        self.kpaValue.text = String(data.kpa)
        self.qnhValue.text = inHgToString(inhg: data.qnh)
        self.inhgValue.text = inHgToString(inhg: data.inHg)
        
        if let altitude = data.altitude {
            self.altitudeValue.text = altitudeToString(altitude: altitude)
        } else {
            self.altitudeValue.text = "--"
        }
    }

    @IBAction func submitQNH(_ sender: Any) {
        let altimeter = barometerService.setQNH(qnh: pressureValueList[selectedPressureValue])
        applyAltitudeData(data: altimeter)
    }
    
    @IBAction func submitDebugPressure(_ sender: Any) {
        let altimeter = barometerService.setIndicatedPressure(inHg: pressureValueList[selectedPressureValue])
        applyAltitudeData(data: altimeter)
    }
    
    func convertPressureText(text: String) -> Double {
        let scale: Int16 = 2
        let behavior = NSDecimalNumberHandler(roundingMode: .plain, scale: scale, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: true)
        
        let dn = NSDecimalNumber(string: text).rounding(accordingToBehavior: behavior)
        return Double(truncating: dn)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pressureValueList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return inHgToString(inhg: pressureValueList[row])
        
        //String(pressureValueList[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPressureValue = row;
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

extension Double {
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}
