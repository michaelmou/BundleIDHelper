//
//  PlistHelper.swift
//  BundleIDHelper
//
//  Created by MichaelMo on 9/28/16.
//  Copyright © 2016 MichaelMo. All rights reserved.
//

import Foundation

let fileName = "bundleIDs.plist"
let bundleIdKey = "bundleIdKey"

class PlistHelper {
    
    let path:String!
    
    init?(path:String?) {
        if path == nil {
            return nil
        }
        self.path = path
    }
    
    func readAllBundleIDs() -> [String]?{
        if let dic = self.read(){
            return dic[bundleIdKey] as? [String]
        }else{
            let _ = self.write(dic: [:])
        }
        return nil
    }
    
    func storeBundleIDs(bundleIDs:[String]) -> Bool {
        var dic = self.read()
        if dic == nil {
            dic = [:]
        }
        
        dic![bundleIdKey] = bundleIDs as AnyObject
        return self.write(dic: dic!)
    }
    
    func addBundleID(bundleID:String) -> Bool {
        var dic = self.read()
        if dic == nil {
            dic = [:]
        }
        var bundleIDs:[String]!
        bundleIDs = dic?[bundleIdKey] as? [String]

        if bundleIDs == nil {
            bundleIDs = [String]()
        }
        bundleIDs!.append(bundleID)
        dic![bundleIdKey] = bundleIDs as AnyObject
        
        return self.write(dic: dic!)
    }
    
    private func read() -> [String:AnyObject]? {
        let dicNS = NSDictionary(contentsOfFile: self.getFilePath())
        return dicNS as? [String:AnyObject]
    }
    
    private func write(dic:[String:AnyObject]) -> Bool{
        let dicNS = dic as NSDictionary
        return dicNS.write(toFile: self.getFilePath(), atomically: true)
    }
    
    private func getFilePath() -> String {
        return self.path+"/"+fileName
    }
    
}
