//
//  UpdateAppAction.swift
//  Patched Sur
//
//  Created by Benjamin Sova on 11/27/20.
//

import SwiftUI
import Files

func updatePatchedApp(completion: ((Bool) -> ())? = nil) {
    
    // MARK: Reality Checks
    
    print("")
    print("Starting Update of Patched Sur...")
    guard let newApp = try? Folder(path: "~/.patched-sur/Patched Sur.app") else {
        if completion == nil {
            print("\n==========================================\n")
            print("Error 0x1")
            print("Can't find new app at ~/.patched-sur/Patched Sur.app")
            print("Make sure the old app correctly downloaded this app and try again.")
            let errorAlert = NSAlert()
            errorAlert.alertStyle = .critical
            errorAlert.informativeText = "Can't find replacement app for update. Make sure the old version of Patched Sur finished downloading the update."
            errorAlert.messageText = "Failed to Update Patched Sur"
            errorAlert.runModal()
            print("\n==========================================\n")
            print("Patched Sur Updater failed.")
        } else {
            (completion ?? {_ in})(false)
        }
        return
    }
    print("Patched Sur.app detected at \(newApp.path)")
//    guard (try? File(path: "~/.patched-sur/Patched Sur.app/Contents/MacOS/Patched Sur")) != nil else {
//        if completion == nil {
//            print("\n==========================================\n")
//            print("Error 0x2")
//            print("Invalid Patched Sur app detected.")
//            print("Make sure the old app correctly downloaded this app and try again.")
//            let errorAlert = NSAlert()
//            errorAlert.alertStyle = .critical
//            errorAlert.informativeText = "Can't find a valid replacement app for update. Make sure the old version of Patched Sur finished downloading the update."
//            errorAlert.messageText = "Failed to Update Patched Sur"
//            errorAlert.runModal()
//            print("\n==========================================\n")
//            print("Patched Sur Updater failed.")
//        } else {
//            (completion ?? {_ in})(false)
//        }
//        return
//    }
//    print("Validated Patched Sur.app")
    print("")
    
    // MARK: Copy Over Files
    
    print("Deleting old copy of Patched Sur")

    do {
        try call("rm -r '/Applications/Patched Sur.app'")
        try call("[[ ! -d '/Applications/Patched Sur.app' ]]")
    } catch {
        if completion == nil {
            print("\n==========================================\n")

            print("Failed to delete the old copy of Patched Sur.app in the Applications folder.")
            print(error.localizedDescription)

            let errorAlert = NSAlert()
            errorAlert.alertStyle = .critical
            errorAlert.informativeText = error.localizedDescription
            errorAlert.messageText = "Failed to Update Patched Sur"
            errorAlert.runModal()

            print("\n==========================================\n")
            print("Patched Sur Updater failed.")
        } else {
            (completion ?? {_ in})(false)
        }
        return
    }
    
    print("Starting copy of \(newApp.path) to /Applications/Patched Sur.app")
    
    do {
        try call("cp -rf ~/.patched-sur/Patched\\ Sur.app /Applications")
    } catch {
        if completion == nil {
            print("\n==========================================\n")
            
            print("Failed to move Patched Sur.app to the Applications folder.")
            print(error.localizedDescription)
            
            let errorAlert = NSAlert()
            errorAlert.alertStyle = .critical
            errorAlert.informativeText = error.localizedDescription
            errorAlert.messageText = "Failed to Update Patched Sur"
            errorAlert.runModal()
            
            print("\n==========================================\n")
            print("Patched Sur Updater failed.")
        } else {
            (completion ?? {_ in})(false)
        }
        return
    }
    
    print("Patched Sur was copied over!")
    print("")
    
    // MARK: Finish Up
    
    print("Switching to full Patched Sur...")
    
    if completion == nil {
        guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "u-bensova.Patched-Sur") else {
            print("Failed to open Patched Sur app, but you can do that yourself.")
            let errorAlert = NSAlert()
            errorAlert.alertStyle = .critical
            errorAlert.informativeText = "Failed to open Patched Sur, but you can do this yourself."
            errorAlert.messageText = "Update Done!"
            errorAlert.runModal()
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: appUrl, configuration: configuration) { (_, error) in
            if error != nil {
                print("Failed to open Patched Sur app, but you can do that yourself.")
                let errorAlert = NSAlert()
                errorAlert.alertStyle = .critical
                errorAlert.informativeText = "Failed to open Patched Sur, but you can do this yourself."
                errorAlert.messageText = "Update Done!"
                errorAlert.runModal()
            }
        }
    }
    
    (completion ?? {_ in})(true)
    
    print("Closing Patched Sur updater...")
    print("")
    print("Patched Sur Updater Succeeded!")
}
