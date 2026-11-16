//
//  Driver.swift
//  eqMac
//
//  Created by Roman Kisil on 30/10/2018.
//  Copyright © 2018 Roman Kisil. All rights reserved.
//

import Foundation
import AMCoreAudio
import CoreFoundation
import Version
import EmitterKit
import Shared

class Driver {
  static func check (_ completion: @escaping() -> Void) {
    if !Driver.isInstalled || !Driver.isCompatible {
      // This build uses its own driver (eqMacFork.driver), separate from the official
      // eqMac driver, so the official installer can't fix this; point at the fork's docs.
      let isIncompatible = Driver.isInstalled && !Driver.isCompatible
      let message = isIncompatible ?
        "The installed eqMacFork audio driver (\(installedVersion)) doesn't match this build of eqMac. Rebuild and reinstall it with native/scripts/install-driver.sh, then start eqMac again."
        : "This build of eqMac needs its own audio driver (eqMacFork.driver), which isn't installed or isn't loaded yet. Install it with native/scripts/install-driver.sh, then start eqMac again."
      let title = isIncompatible ? "The eqMac audio driver is incompatible" : "The eqMac audio driver is not installed"
      Alert.withButtons(
        title: title,
        message: message,
        buttons: ["Open Install Instructions", "Quit"]
      ) { buttonPressed in
        if NSApplication.ModalResponse(buttonPressed) == .alertFirstButtonReturn {
          NSWorkspace.shared.open(Constants.DRIVER_INSTALL_DOCS_URL)
        }
        return Application.quit()
      }
    } else {
      completion()
    }
  }

  private static var showChecks: Int = 0
  private static var showCheckQueue: DispatchQueue?

  static func show (_ completion: @escaping() -> Void) {
    if (hidden) {
      shown = true
      showChecks = 0
      showCheckQueue = DispatchQueue(label: "check-driver-shown", qos: .userInteractive)
      showCheckQueue!.asyncAfter(deadline: .now() + .milliseconds(500)) {
        return waitAndCheckForShown(completion)
      }
    } else {
      completion()
    }
  }
  private static func waitAndCheckForShown (_ completion: @escaping() -> Void) {
    showChecks += 1
    if (device == nil) {
      if (showChecks > 5) {
        return failedToShowPrompt()
      }
      showCheckQueue!.asyncAfter(deadline: .now() + .milliseconds(500)) {
        return waitAndCheckForShown(completion)
      }
      return
    }
    showCheckQueue = nil
    completion()
  }

  private static func failedToShowPrompt () {
    Alert.confirm(
    title: "Driver failed to activate", message: "Unfortunately the audio driver has failed to active. You can restart eqMac and try again or quit.", okText: "Try again", cancelText: "Quit") { restart in
      if restart {
        return Application.restart()
      } else {
        return Application.quit()
      }
    }
  }

  static var pluginId: AudioObjectID? {
    return AudioDevice.lookupIDByPluginBundleID(by: DRIVER_BUNDLE_ID)
  }
  
  static var isInstalled: Bool {
    get {
      return self.device != nil || self.pluginId != nil
    }
  }

  static var name: String {
    get {
      return device!.name
    }
    set {
      let size = Memory.sizeof(CFString.self)
      var name = newValue as CFString
      checkErr(AudioObjectSetPropertyData(Driver.device!.id, &EQMDeviceCustom.addresses.name, 0, nil, size, &name))
    }
  }

  static var latency: UInt32 {
    get {
      return Driver.device!.latency(direction: .playback)!
    }
    set {
      let size = Memory.sizeof(CFNumber.self)

      var newLatency = newValue
      var latency: CFNumber = CFNumberCreate(kCFAllocatorDefault, CFNumberType.sInt32Type, &newLatency)
      
      checkErr(AudioObjectSetPropertyData(Driver.device!.id, &EQMDeviceCustom.addresses.latency, 0, nil, size, &latency))
    }
  }

  static var shown: Bool {
    get {
      if Driver.device == nil { return false }
      var size: UInt32 = UInt32(MemoryLayout<CFBoolean>.size)
      
      var shownBool = kCFBooleanFalse
      
      let err = AudioObjectGetPropertyData(Driver.device!.id, &EQMDeviceCustom.addresses.shown, 0, nil, &size, &shownBool)
      if err == noErr {
        return CFBooleanGetValue(shownBool!)
      }
      
      // Workaround around a bug in the Driver where it wasn't aware of address
      return Driver.device!.canBeDefaultDevice(direction: .playback)
    }
    set {
      if Driver.device == nil { return }
      
      let size: UInt32 = UInt32(MemoryLayout<CFBoolean>.size)
      var shownBool: CFBoolean = newValue.cfBooleanValue
      
      checkErr(AudioObjectSetPropertyData(Driver.device!.id, &EQMDeviceCustom.addresses.shown, 0, nil, size, &shownBool))
    }
  }
  
  static var installedVersion: Version {
    if Driver.device == nil { return .null }
    var size: UInt32 = UInt32(MemoryLayout<CFString>.size)
    
    var version: CFString? = nil
    
    checkErr(AudioObjectGetPropertyData(Driver.device!.id, &EQMDeviceCustom.addresses.version, 0, nil, &size, &version))

    let verStr = version as String?
    return verStr != nil ? (Version(tolerant: verStr!) ?? .null) : .null
  }
  
  static var isCompatible: Bool {
    let compatibleRange = Constants.DRIVER_MINIMUM_VERSION ..< Version(2, 0, 0)
    return compatibleRange.contains(installedVersion)
  }
  
  static var hidden: Bool {
    get { return !shown }
    set { shown = !newValue }
  }
  
  static var device: AudioDevice? {
    return AudioDevice.lookup(by: Constants.DRIVER_DEVICE_UID)
  }
  
}

