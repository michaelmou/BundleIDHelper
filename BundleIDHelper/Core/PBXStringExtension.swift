//
//  PBXStringExtension.swift
//  BundleIDHelper
//
//  Created by MichaelMo on 9/26/16.
//  Copyright © 2016 MichaelMo. All rights reserved.
//

import Foundation

// MARK: - 在 string 里面按 pattern 查找
extension String {
	func searchUserPattern(_ pattern: String) -> [NSTextCheckingResult]? {
		// 定义正则表达式
		let pattern = pattern;
		guard let regular = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
		return regular.matches(in: self, options: .reportProgress, range: NSMakeRange(0, self.characters.count))
	}

	func find(_ pattern: String) -> [String]? {
		var results: [String]?
		if let resultSets = self.searchUserPattern(pattern)?.dropFirst() {
			for result in resultSets {
				if results == nil {
					results = [String]()
				}
				if let range = self.rangeFromNSRange(result.range) {
					var substring = self.substring(with: range)
					substring = substring[substring.index(substring.startIndex, offsetBy: 2)..<substring.index(substring.endIndex, offsetBy: -1)]
					results!.append(substring)
				}
			}
		}

		return results
	}
}

// MARK: - NSRange -> Range;
extension String {
	mutating func replaceNSRange(_ subNSRange: NSRange, with: String) {
		guard let range = self.rangeFromNSRange(subNSRange) else { return }
		self.replaceSubrange(range, with: with)
	}
}

// MARK: - 在 string 里替换掉 bundleID
extension String {
	mutating func replaceBundleIDInPiece(_ bundleID: String) {
		let pre = "=(.*);"
		guard let result = self.searchUserPattern(pre) else { return }

		let identifier = " " + bundleID
		var nsrange = result.last!.range
		nsrange.length -= 2
		nsrange.location += 1

		guard let rangeOfOrID = self.rangeFromNSRange(nsrange) else { return }
		self.replaceSubrange(rangeOfOrID, with: identifier)
	}
}

// MARK: - 读出 bundleID
extension String {

	func readBundleIDPiece(_ results: [NSTextCheckingResult]?, pattern: String) -> ([String]?, [NSTextCheckingResult]?)? {
		var resultStrings = [String]()
		var resultsCurrent = results
		/**
         *  这里待优化，改成多线程搜索；线程数应该为 CPU 的核心数, 切成 n 段查找，n 为 CPU 核心数
         *  需要注意线程的调度
         */

		if nil == resultsCurrent {
			guard let temp = self.searchUserPattern(pattern) else { return nil }
			resultsCurrent = temp
		}
		for result in resultsCurrent! {
			let returnResult = (self as NSString).substring(with: result.range)
			resultStrings.append(returnResult)
		}
		return (resultStrings, resultsCurrent)
	}
}

// MARK: - 用NSRange 替换 string
extension String {
	func rangeFromNSRange(_ nsRange: NSRange) -> Range<String.Index>? {
		let from16 = utf16.startIndex.advanced(by: nsRange.location)
		let to16 = from16.advanced(by: nsRange.length)
		if let from = String.Index(from16, within: self),
			let to = String.Index(to16, within: self) {
				return from ..< to
		}
		return nil
	}

	mutating func replaceBundleID(_ bundleID: String, resultSet: [NSTextCheckingResult]) {

		let content2s = self.readBundleIDPiece(nil, pattern: pattern)!.0!
		for (index, result) in resultSet.reversed().enumerated() {
			var content2 = content2s[index]
			content2.replaceBundleIDInPiece(bundleID)
			self.replaceNSRange(result.range, with: content2)
		}
	}
}
