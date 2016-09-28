//
//  PBXProject.swift
//  BundleIDHelper
//
//  Created by MichaelMo on 9/26/16.
//  Copyright © 2016 MichaelMo. All rights reserved.
//

import Foundation

let pattern = "OTHER_LDFLAGS = \"-ObjC\";\n(.*)PRODUCT_BUNDLE_IDENTIFIER = (.*);"
let patternInShort = "=(.*);"
let project_pbxproj = "/project.pbxproj"
let queueName = "BundleIDHelper"

class PBXProjectController {

	var reslutSet = [String: NSTextCheckingResult]()
	static let shareInstance = PBXProjectController()
	private let cache = NSCache<NSString, NSString>()
	let queue = DispatchQueue(label: queueName, attributes: .concurrent)
	let lock = NSLock()
    var currentProjectPath:String?

	private init() { }

    private func readFile(path: String, isIgnoreCache: Bool) throws -> String {
        var path = path
        path += project_pbxproj
		if !isIgnoreCache, let content = self.cache.object(forKey: path as NSString) as? String {
			return content
		} else {
			do {
				let content = try String.init(contentsOfFile: path)
                self.lock.lock()
				self.cache.setObject(content as NSString, forKey: path as NSString)
                self.lock.unlock()
				return content
			} catch {
				print("try to open file \(path)")
				print(error)
				throw error
			}
		}
	}

	func search(projectPath: String, pattern: String, completedClosure: @escaping (([NSTextCheckingResult]?) -> ())) {
		self.queue.async {
			guard let content = try? self.readFile(path: projectPath, isIgnoreCache: true) else {
				DispatchQueue.main.async {
					completedClosure(nil)
				}
				return
			}
			DispatchQueue.main.async {
				completedClosure(content.searchUserPattern(pattern))
			}
		}
	}

	func getBundleIDs(_ projectPath: String, isNeedToReSearch: Bool, completedClosure: @escaping ([String]?) -> Void) {
        
        self.currentProjectPath = projectPath

		self.queue.async {
			guard let content = try? self.readFile(path: projectPath, isIgnoreCache: isNeedToReSearch) else {
				DispatchQueue.main.async {
					completedClosure(nil)
				}
				return
			}

			var currentResultSet: ([String]?, [NSTextCheckingResult]?)?
			if isNeedToReSearch || self.reslutSet[projectPath] == nil {
				currentResultSet = content.readBundleIDPiece(nil, pattern: pattern)
			}
			guard let currentResult = currentResultSet?.1?.first else {
				DispatchQueue.main.async {
					completedClosure(nil)
				}
				return
			}
			self.reslutSet[projectPath] = currentResult
			var budleIDs = [String]()
			for piece in currentResultSet!.0! {
				if let bundleID = piece.find(patternInShort) {
					budleIDs += bundleID
				}
			}

			DispatchQueue.main.async {
				completedClosure(budleIDs)
			}
		}
	}

	func replaceBundleID(projectPath: String?, isNeedToReSearch: Bool, bundleID: String, completedClosure: @escaping ((Bool) -> Void)) {
        
        let path = projectPath ?? self.currentProjectPath ?? nil
        if path == nil{
            completedClosure(false)
            return
        }
        let projectPath = path!

		self.queue.async {
			guard var content = try? self.readFile(path: projectPath, isIgnoreCache: isNeedToReSearch) else {
				DispatchQueue.main.sync {
					completedClosure(false)
				}
				return
			}
			var currentResultSet: ([String]?, [NSTextCheckingResult]?)?
			if isNeedToReSearch || self.reslutSet[projectPath] == nil {
				currentResultSet = content.readBundleIDPiece(nil, pattern: pattern)
			}
			guard let currentResult = currentResultSet?.1?.first else {
				DispatchQueue.main.sync {
					completedClosure(false)
				}
				return
			}
			self.reslutSet[projectPath] = currentResult
            self.lock.lock()
			content.replaceBundleID(bundleID, resultSet: [currentResult])
			do {
				try content.write(toFile: projectPath + project_pbxproj, atomically: true, encoding: String.Encoding.utf8)
			} catch let error {
				print(error)
                self.lock.unlock()
				DispatchQueue.main.sync {
					completedClosure(false)
				}
                return
			}
            self.lock.unlock()
			DispatchQueue.main.sync {
				completedClosure(true)
			}

		}

	}
}
