//
//  BundleIDHelper.swift
//
//  Created by MichaelMo on 9/27/16.
//  Copyright © 2016 MichaelMo. All rights reserved.
//

import AppKit

var sharedPlugin: BundleIDHelper?

class BundleIDHelper: NSObject {

	let bundle: Bundle
	lazy var center = NotificationCenter.default
	let pbnxProjectController = PBXProjectController.shareInstance
    var menuItem4BundleIDHelper:NSMenuItem!
    let menuItem4AddCustomedBundleID:NSMenuItem!
    var menu:NSMenu!

    //候选 BundleID
    var candidatecBundleID = Set<String>()

	// MARK: - Initialization

	class func pluginDidLoad(_ bundle: Bundle) {
		let allowedLoaders = bundle.object(forInfoDictionaryKey: "me.delisa.XcodePluginBase.AllowedLoaders") as! Array<String>
		if allowedLoaders.contains(Bundle.main.bundleIdentifier ?? "") {
			sharedPlugin = BundleIDHelper(bundle: bundle)
		}
	}

	init(bundle: Bundle) {
		self.bundle = bundle
        
        self.menuItem4AddCustomedBundleID = NSMenuItem.init(title: "Add your own BundleID", action: #selector(self.addYourBundleID(sender:)), keyEquivalent: "")
		super.init()
        self.menuItem4AddCustomedBundleID.target = self
		// NSApp may be nil if the plugin is loaded from the xcodebuild command line tool
		if (NSApp != nil && NSApp.mainMenu == nil) {
			center.addObserver(self, selector: #selector(self.applicationDidFinishLaunching), name: NSNotification.Name.NSApplicationDidFinishLaunching, object: nil)
			center.addObserver(self, selector: #selector(self.projectDidClose(notification:)), name: NSNotification.Name(rawValue: "PBXProjectDidOpenNotification"), object: nil)
			center.addObserver(self, selector: #selector(self.projectDidClose(notification:)), name: NSNotification.Name(rawValue: "PBXProjectDidChangeNotification"), object: nil)
			center.addObserver(self, selector: #selector(self.projectDidClose(notification:)), name: NSNotification.Name(rawValue: "PBXProjectDidCloseNotification"), object: nil)
			center.addObserver(self, selector: #selector(self.applicationDidBecomeActive(_:)), name: NSNotification.Name.NSApplicationDidBecomeActive, object: nil)
		} else {
			initializeAndLog()
		}
	}

	fileprivate func initializeAndLog() {
		let name = bundle.object(forInfoDictionaryKey: "CFBundleName")
		let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")
		let status = initialize() ? "loaded successfully" : "failed to load"
		NSLog("🔌 Plugin \(name) \(version) \(status)")
	}

	func applicationDidFinishLaunching() {
		center.removeObserver(self, name: NSNotification.Name.NSApplicationDidFinishLaunching, object: nil)
		initializeAndLog()
	}

	// MARK: - Implementation

	func initialize() -> Bool {
		guard let mainMenu = NSApp.mainMenu else { return false }
		guard let item = mainMenu.item(withTitle: "Edit") else { return false }
		guard let submenu = item.submenu else { return false }

		self.menuItem4BundleIDHelper = NSMenuItem(title: "BundleIDHelper", action: nil, keyEquivalent: "")
        
		submenu.addItem(NSMenuItem.separator())
		submenu.addItem(self.menuItem4BundleIDHelper)

		return true
	}

}

// MARK: - Notifications
extension BundleIDHelper{
    func projectDidChange(notification: Notification) {
        if let path = notification.filePathForProject() {
            print(path)
            pbnxProjectController.getBundleIDs(path as String, isNeedToReSearch: false
                , completedClosure: {
                    if let result = $0 {
                        self.addBundleID(bundleID: result.first!)
                    }
                    
            })
            print("notification:\(notification.name)")
        }
    }
    
    func projectDidClose(notification: Notification) {
        if let path = notification.filePathForProject() {
            print(path)
            
            pbnxProjectController.getBundleIDs(path as String, isNeedToReSearch: false
                , completedClosure: {
                    if let result = $0 {
                        self.addBundleID(bundleID: result.first!)
                    }
            })
            print("notification:\(notification.name)")
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if let path = notification.filePathForProject() {
            print(path)
            pbnxProjectController.getBundleIDs(path as String, isNeedToReSearch: false
                , completedClosure: {
                    if let result = $0 {
                        self.addBundleID(bundleID: result.first!)
                    }
            })
            print("notification:\(notification.name)")
        }
    }
}

// MARK: - Event
extension BundleIDHelper{
    func doMenuAction(sender:NSMenuItem) {
        pbnxProjectController.replaceBundleID(projectPath: nil, isNeedToReSearch: true, bundleID: sender.title) { (succeed) in
            let alert = NSAlert()
            alert.messageText = succeed ? "Bundle ID modifying succeed" : "Bundle ID modifying failure"
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    func addYourBundleID(sender:AnyObject) {
        let alert = NSAlert.init()
        alert.alertStyle = .informational
        alert.messageText = "Add your own Bundle ID"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let textField = NSTextField(frame: NSMakeRect(0, 0, 200, 24))
        alert.accessoryView = textField
        let response = alert.runModal()
        if response == NSAlertFirstButtonReturn {
            let text = textField.stringValue as String
            if text != ""{
                let originCount = candidatecBundleID.count
                candidatecBundleID.insert(text)
                if originCount < candidatecBundleID.count{
                    let succeed = PlistHelper.init(path: self.bundle.resourcePath!)?.addBundleID(bundleID: text)
                    if let succeed = succeed , succeed {
                        let menuItem = NSMenuItem(title: text, action: #selector(self.doMenuAction(sender:)), keyEquivalent: "")
                        menuItem.target = self
                        self.menu.addItem(menuItem)
                    }
                }else{
                    let error = NSError.init(domain: "Duplicate bundle id", code: -1, userInfo: nil)
                    NSAlert(error: error).runModal()
                }
            }
        }
        print("response\(response)")
    }
}

// MARK: - Handle Bundle show and add
extension BundleIDHelper{
    func addBundleID(bundleID:String) {
        let currentBundleID = bundleID
        
        let originCount = candidatecBundleID.count
        candidatecBundleID.insert(currentBundleID)
        if originCount < candidatecBundleID.count {
            
            if nil == self.menu {
                self.menu = NSMenu(title: "BundleIDHelper")
                self.menu.addItem(self.menuItem4AddCustomedBundleID)
                self.menuItem4BundleIDHelper.submenu = self.menu
                self.menu.addItem(NSMenuItem.separator())
                
                if let bundleIDsOfUser = PlistHelper.init(path: self.bundle.resourcePath)?.readAllBundleIDs(){
                    for id in bundleIDsOfUser{
                        let menuItem = NSMenuItem(title: id, action: #selector(self.doMenuAction(sender:)), keyEquivalent: "")
                        menuItem.target = self
                        self.menu.addItem(menuItem)
                    }
                }
            }
            
            let menuItem = NSMenuItem(title: currentBundleID, action: #selector(self.doMenuAction(sender:)), keyEquivalent: "")
            menuItem.target = self
            self.menu.insertItem(menuItem, at: 2)
            
        }
    }
    

}
