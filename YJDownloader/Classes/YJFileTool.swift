//
//  YJFileTool.swift
//  YJDownloader
//
//  Created by ddn on 2017/6/23.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation
import MobileCoreServices

public class YJFileTool {

	public class func cache() -> String {
		return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
	}
	
	public class func tmp() -> String {
		return NSTemporaryDirectory()
	}
	
	public class func create(_ filePath: String?) {
		if filePath == nil {return}
		if exists(filePath) {return}
		try? FileManager.default.createDirectory(atPath: filePath!, withIntermediateDirectories: true)
	}
	
	public class func exists(_ filePath: String?) -> Bool {
		guard let filePath = filePath else {return false}
		return FileManager.default.fileExists(atPath: filePath)
	}
	
	public class func remove(_ filePath: String?) {
		guard let filePath = filePath else {return}
		try? FileManager.default.removeItem(atPath: filePath)
	}
	
	public class func move(_ filePath: String?, toPath: String?) {
		guard let filePath = filePath, let toPath = toPath else {return}
		try? FileManager.default.moveItem(atPath: filePath, toPath: toPath)
	}
	
	public class func size(_ filePath: String?) -> UInt64 {
		guard let filePath = filePath else {return 0}
		if let size = try? FileManager.default.attributesOfItem(atPath: filePath)[.size] {
			return size as! UInt64
		}
		return 0
	}
    
    public class func contentType(_ url: URL) -> String? {
        let fileExtension = (url.absoluteString as NSString).pathExtension
        let contentTypeCFManager = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)
        let contentTypeCF = contentTypeCFManager?.takeUnretainedValue()
        contentTypeCFManager?.release()
        return contentTypeCF as String?
    }
}
