//
//  UpdateChooser.swift
//  Patched Sur
//
//  Created by Ben Sova on 4/7/21.
//

import VeliaUI
import Files

struct UpdateChooser: View {
    @Binding var p: Int
    @State var fetchedInstallers = nil as InstallAssistants?
    @State var publicInstallers = nil as InstallAssistants?
    @Binding var installInfo: InstallAssistant?
    @Binding var track: ReleaseTrack
    @State var current = nil as InstallAssistant?
    @State var errorL = nil as String?
    @State var buttonBG = Color.red
    @State var hovered = nil as String?
    @Binding var useCurrent: Bool
    @Binding var package: String
    @State var selfV = ""
    @State var alert: Alert?
    
    var body: some View {
        HStack(spacing: 15) {
            VIHeader(p: "Update Chooser", s: "v\(AppInfo.version) (\(AppInfo.build))", c: .constant(true))
                .alignment(.leading)
            Spacer()
            VIButton(id: "BACK", h: $hovered) {
                Image("BackArrow")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .scaleEffect(1.2)
            } onClick: {
                withAnimation {
                    p = 2
                }
            }
            VIButton(id: "BROWSE", h: $hovered) {
                Image("Package")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .scaleEffect(1.2)
            } onClick: {
                print("Initializing browse panel")
                let dialog = NSOpenPanel()

                dialog.title = "Choose an macOS Big Sur Installer"
                dialog.showsResizeIndicator = false
                dialog.allowsMultipleSelection = false
                dialog.allowedFileTypes = ["app", "pkg"]

                guard dialog.runModal() == NSApplication.ModalResponse.OK else { print("Browser was canceled"); return }
                
                print("Received response")
                
                guard let result = dialog.url else { print("There was no result..."); return }
                let path: String = result.path
                
                guard verifyInstaller(alert: &alert, path: path) else { return }
                
                print("Saving installInfo")
                if path.hasSuffix("pkg") {
                    print("(It's a package)")
                    installInfo = .init(url: path, date: "", buildNumber: "CustomPKG", version: "", minVersion: 0, orderNumber: 0, notes: nil)
                } else if path.hasSuffix("app") {
                    print("(It's an app)")
                    installInfo = .init(url: path, date: "", buildNumber: "CustomAPP", version: "", minVersion: 0, orderNumber: 0, notes: nil)
                } else {
                    fatalError(path)
                }
                _ = try? call("sleep 1")
                withAnimation {
                    p = 3
                }
            }.alert($alert)
        }.padding(.top, 40)
        
        // MARK: Content
        
        if let errorL = errorL {
            Spacer(minLength: 0)
            Text("An error occurred while fetching available updates.")
            VIError(errorL)
            Spacer(minLength: 0)
        } else if fetchedInstallers == nil {
            Spacer(minLength: 0)
            VIButton(id: "SOMETHING", h: .constant("12")) {
                Image("DownloadArrow")
                Text("Fetching Installers")
            }.inPad()
            .btColor(.gray)
            .onAppear {
                DispatchQueue(label: "FetchInstallers").async {
                    selfV = (try? call("sw_vers -productVersion")) ?? "11.2.3"
                    fetchInstallerList(track: track) {
                        fetchedInstallers = $0
                    } current: {
                        current = $0
                    } errorL: {
                        errorL = $0
                    }
                }
            }
            Spacer(minLength: 0)
        } else {
            ScrollView {
                if let current = current {
                    Text("This version of macOS is already downloaded:")
                    UpdateSelectCell(installer: current, delete: {
                        print("Making sure we want to delete the installer")
                        let al = NSAlert()
                        al.informativeText = "While this will save you a good 12.2 GBs of storage, it's also useful for quickly reinstalling macOS or really any other reason you might need a 12GB macOS installer."
                        al.messageText = "Are you sure you want to delete the pre-downloaded installer?"
                        al.showsHelp = false
                        al.addButton(withTitle: "Delete")
                        al.addButton(withTitle: "Cancel")
                        switch al.runModal() {
                        case .alertFirstButtonReturn:
                            _ = try? call("rm -rf ~/.patched-sur/InstallAssistant.pkg")
                            _ = try? call("rm -rf ~/.patched-sur/InstallInfo.txt")
                            withAnimation {
                                self.current = nil
                            }
                        default:
                            break
                        }
                    }, selfV: selfV, installInfo: $installInfo, done: {withAnimation { p = 3 }})
                }
                if let fetched = fetchedInstallers {
                    Text("You can download these versions of macOS:")
                    ForEach(fetched, id: \.buildNumber) { installer in
                        UpdateSelectCell(installer: installer, delete: nil, selfV: selfV, installInfo: $installInfo, done: {withAnimation { p = 3 }})
                    }
                }
                Text("")
                    .padding(.bottom)
            }
        }
    }
}

struct UpdateSelectCell: View {
    let installer: InstallAssistant
    let delete: (() -> ())?
    @State var hovered: String?
    let selfV: String
    @Binding var installInfo: InstallAssistant?
    let done: () -> ()
    
    var body: some View {
        HStack {
            ZStack {
                if convertVersionBinary(installer.version) >= convertVersionBinary(selfV) {
                    RadialGradient(gradient: Gradient(colors: installer.version.contains("Beta") || installer.version.contains("RC") ? [Color.purple.opacity(0.3), Color.purple] : [Color("Accent").opacity(0.3), Color("Accent")]), center: .center, startRadius: 1, endRadius: 40)
                        .cornerRadius(20)
                } else {
                    RadialGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray]), center: .center, startRadius: 1, endRadius: 40)
                        .cornerRadius(20)
                }
                Text(installer.version.contains("Beta") || installer.version.contains("RC") ? "B" : "R")
                    .font(.title2)
                    .foregroundColor(.white)
            }.frame(width: 40, height: 40)
            .offset(x: 0, y: 3)
            VStack(alignment: .leading) {
                Text("macOS \(installer.version)")
                    .font(Font.title3.bold())
                Text("Build \(installer.buildNumber) - Released \(installer.localizedDate)")
            }
            Spacer()
            if convertVersionBinary(installer.version) >= convertVersionBinary(selfV) {
                VIButton(id: "UPDDATE\(installer.buildNumber)", h: $hovered) {
                    Image("UpdateCircle")
                    Text(convertVersionBinary(installer.version) > convertVersionBinary(selfV) ? "Update" : "Reinstall")
                } onClick: {
                    if delete == nil {
                        installInfo = .init(url: installer.url, date: "", buildNumber: installer.buildNumber, version: "", minVersion: 0, orderNumber: 0, notes: nil)
                        done()
                    } else {
                        guard let location = try? File(path: "~/.patched-sur/InstallAssistant.pkg") else {
                            presentAlert(m: "An Unexpected Error Occurred", i: "This file appears to be missing and the full patch cannot be determined. You cannot use the pre-downloaded installer for now.")
                            return
                        }
                        installInfo = .init(url: location.path, date: "", buildNumber: "CustomPKG", version: "", minVersion: 0, orderNumber: 0, notes: nil)
                        done()
                    }
                }.inPad()
                if delete == nil {
                    VIButton(id: "DOWNLOAD\(installer.buildNumber)", h: $hovered) {
                        Image("DownloadArrow")
                    } onClick: {
                        let al = NSAlert()
                        al.informativeText = "You can update to this version of macOS, however you can also download it and that's the button you clicked. This popup just exists to make sure you know that. (This will just open your web browser and download the installer, nothing special.)"
                        al.messageText = "Download the macOS Installer"
                        al.showsHelp = false
                        al.addButton(withTitle: "Download")
                        al.addButton(withTitle: "Cancel")
                        switch al.runModal() {
                        case .alertFirstButtonReturn:
                            NSWorkspace.shared.open(URL(string: installer.url)!)
                        default:
                            break
                        }
                    }.btColor(Color.gray).useHoverAccent()
                    .help("You can also download the InstallAssistant.pkg if you want.")
                }
            } else {
                VIButton(id: "UPDDATE\(installer.buildNumber)", h: $hovered) {
                    Image("DownloadArrow")
                    Text("Download")
                } onClick: {
                    let al = NSAlert()
                    al.informativeText = "You can't \"update\" to an older version of macOS, however you can download the installer if you have something you want to do with it. (This will just open your web browser and download the installer, nothing special.)"
                    al.messageText = "Download the macOS Installer"
                    al.showsHelp = false
                    al.addButton(withTitle: "Download")
                    al.addButton(withTitle: "Cancel")
                    switch al.runModal() {
                    case .alertFirstButtonReturn:
                        NSWorkspace.shared.open(URL(string: installer.url)!)
                    default:
                        break
                    }
                }.inPad()
                .btColor(.gray).useHoverAccent()
                .help("You cannot update to an older version of macOS, but you may download this installer if you want.")
            }
            if delete != nil {
                VIButton(id: "DELETEC", h: $hovered) {
                    Image("ThisImageIsTrash")
                } onClick: {
                    delete!()
                }.btColor(.red)
            }
        }
    }
}
