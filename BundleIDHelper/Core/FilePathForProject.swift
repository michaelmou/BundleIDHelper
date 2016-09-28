//
//  FilePathForProject.swift
//  BundleIdHelper
//
//  Created by MichaelMo on 9/22/16.
//  Copyright © 2016 MichaelMo. All rights reserved.
//

import Foundation

extension Notification {

	func filePathForProject() -> NSString? {

		let getPathMethod = "projectRootPaths"
		if let object = self.object as? NSObject, object.responds(to: Selector(getPathMethod)) {
			if let pbxProjPath = object.perform(Selector(getPathMethod)) as? NSString {
				return pbxProjPath
			}
		}

		return ProjectPathHelper.workspacePath() as NSString?

	}

}
