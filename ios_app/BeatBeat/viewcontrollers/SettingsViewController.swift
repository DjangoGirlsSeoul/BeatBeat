//
//  SettingsViewController.swift
//  BeatBeat
//
//  Created by Hassan Abid on 10/11/16.
//  Copyright © 2016 Google. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {

    // MARK: - properties
    
    public static let SOCKET_KEY = "socket"
    public static let DEBUG_KEY = "debug"
    public static let IPADDRESS_KEY = "ipadress"
    public static let LANGUAGE_KEY = "language"
    public static let BYTES_PER_SAMPLE_KEY = "bytes_per_sample"
    public static let PORT_NUMBER_KEY = "port"
    
    @IBOutlet weak var debugSwitch: UISwitch!
    @IBOutlet weak var socketSwitch: UISwitch!
    @IBOutlet weak var ipAddressTextField: UITextField!
    @IBOutlet weak var bytesTextField: UITextField!
    @IBOutlet weak var portNumberTextField: UITextField!
    
    let defaults = UserDefaults.standard

    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDefaultSwitch()
        configureTextField()
    }

    // MARK: - Configuration
    
    func configureDefaultSwitch() {
        
        let val = defaults.bool(forKey: SettingsViewController.SOCKET_KEY)
        socketSwitch.setOn(val, animated: false)
        
        let debugVal = defaults.bool(forKey: SettingsViewController.DEBUG_KEY)
        debugSwitch.setOn(debugVal, animated: false)
        
        socketSwitch.addTarget(self, action: #selector(SettingsViewController.switchValueDidChange(aSwitch:)), for: .valueChanged)
        
        debugSwitch.addTarget(self, action: #selector(SettingsViewController.debugSwitchValueDidChange(aSwitch:)), for: .valueChanged)
    }
    
    func configureTextField() {
    
    
        if let ip = defaults.string(forKey: SettingsViewController.IPADDRESS_KEY) {
            ipAddressTextField.text = ip
        } else  {
            ipAddressTextField.placeholder = NSLocalizedString("Server IP Address", comment: "")
        }
        ipAddressTextField.autocorrectionType = .no
        ipAddressTextField.returnKeyType = .done
        ipAddressTextField.clearButtonMode = .never
        
        bytesTextField.text = "\(defaults.integer(forKey: SettingsViewController.BYTES_PER_SAMPLE_KEY))"
        
        bytesTextField.autocorrectionType = .no
        bytesTextField.keyboardType = .numberPad
        bytesTextField.clearButtonMode = .never
        bytesTextField.returnKeyType = .done
        
        portNumberTextField.text = "\(defaults.integer(forKey: SettingsViewController.PORT_NUMBER_KEY))"
        
        portNumberTextField.autocorrectionType = .no
        portNumberTextField.keyboardType = .numberPad
        portNumberTextField.clearButtonMode = .never
        portNumberTextField.returnKeyType = .done
        
    }

    // MARK: - Actions
    
    func switchValueDidChange(aSwitch: UISwitch) {
        NSLog("A switch changed its value: \(aSwitch.isOn).")
        defaults.set(aSwitch.isOn, forKey: SettingsViewController.SOCKET_KEY)
    }
    
    func debugSwitchValueDidChange(aSwitch: UISwitch) {
        NSLog("A switch changed its value: \(aSwitch.isOn).")
        defaults.set(aSwitch.isOn, forKey: SettingsViewController.DEBUG_KEY)
    }
    
    
    
    
    @IBAction func didTouchDone(_ sender: UIBarButtonItem) {
        
        //TODO : save values
        
        if let text = ipAddressTextField.text {
            defaults.set(text, forKey: SettingsViewController.IPADDRESS_KEY)
        }
        
        if let portText = portNumberTextField.text {
            defaults.set(Int(portText), forKey: SettingsViewController.PORT_NUMBER_KEY)
        }
        
        
        if let bytes_text = bytesTextField.text {
            defaults.set(Int(bytes_text), forKey: SettingsViewController.BYTES_PER_SAMPLE_KEY)

        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }

}
