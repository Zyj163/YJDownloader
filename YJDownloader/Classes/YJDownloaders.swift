//
//  YJDownloaders.swift
//  YJDownloader
//
//  Created by ddn on 2017/6/23.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation
import CryptoSwift

public class YJDownloaders: NSObject {
	public static let downloaders = YJDownloaders()
	
	fileprivate lazy var session : URLSession = {
		let config = URLSessionConfiguration.default
		
		return URLSession(configuration: config, delegate: self, delegateQueue: nil)
		}()
	
	fileprivate lazy var cachePath: String = {
		let path = YJFileTool.cache().appending("/yjdownloads")
		YJFileTool.create(path)
		return path
	}()
	fileprivate lazy var tmpPath: String = {
		let path = YJFileTool.tmp().appending("/yjdownloads")
		YJFileTool.create(path)
		return path
	}()
	
	fileprivate lazy var queue: YJDownloadersQueue = {
		let queue = YJDownloadersQueue(self.session)
		queue.tmpPath = self.tmpPath
		queue.cachePath = self.cachePath
		return queue
	}()
	
	public var maxRunningCount: Int = 3 {
		didSet {
			queue.maxRunningCount = maxRunningCount
		}
	}
	
	private override init() {
		super.init()
	}
}
 
extension YJDownloaders {
	public class func yj_shared() -> YJDownloaders {
		return downloaders
	}
}

extension YJDownloaders {
	
	public func yj_reset(_ tmpPath: String? = nil, cachePath: String? = nil) {
		yj_cancelAll()
		if let tmpPath = tmpPath {
			self.tmpPath = tmpPath
			YJFileTool.create(tmpPath)
		}
		if let cachePath = cachePath {
			self.cachePath = cachePath
			YJFileTool.create(cachePath)
		}
		queue.reset()
	}
	
	public func yj_removeTmpFiles(_ urls: [URL]? = nil, filePaths: [String]? = nil) {
		urls?.forEach{
			if let downloader = queue.downloader(forUrl: $0) {
				downloader.yj_removeTmp()
				queue.removeDownloader(forUrl: $0)
			} else {
				let fileName = $0.lastPathComponent
				let path = self.tmpPath.appending("/\(fileName)")
				YJFileTool.remove(path)
			}
		}
		filePaths?.forEach{
			if $0.hasPrefix(self.tmpPath) {
				YJFileTool.remove($0)
			}
		}
	}
	
	public func yj_removeCacheFiles(_ urls: [URL]? = nil, filePaths: [String]? = nil) {
		urls?.forEach{
			if let downloader = queue.downloader(forUrl: $0) {
				downloader.yj_removeCache()
			} else {
				let fileName = $0.lastPathComponent
				let path = self.cachePath.appending("/\(fileName)")
				YJFileTool.remove(path)
			}
		}
		filePaths?.forEach{
			if $0.hasPrefix(self.cachePath) {
				YJFileTool.remove($0)
			}
		}
	}
	
	public func yj_removeTmp(_ path: String? = nil) {
		yj_cancelAll()
		if let path = path {
			YJFileTool.remove(path)
		} else {
			YJFileTool.remove(tmpPath)
		}
	}
	
	public func yj_removeCache(_ path: String? = nil) {
		if let path = path {
			YJFileTool.remove(path)
		} else {
			YJFileTool.remove(cachePath)
		}
	}
	
	public func yj_download(_ url: URL, destination: String? = nil, stateChanged:((YJDownloaderState)->Void)? = nil, progressChanged:((Double)->Void)? = nil, receiveTotalSize: ((UInt64)->Void)? = nil) {
		
		queue.addDownloader(url, destination: destination, stateChanged: stateChanged, progressChanged: progressChanged, receiveTotalSize: receiveTotalSize)
	}
	
	public func yj_pause(_ url: URL) {
		queue.pause(url)
	}
	
	public func yj_resume(_ url: URL) {
		queue.resume(url)
	}
	
	public func yj_cancel(_ url: URL) {
		queue.cancel(url)
	}
	
	public func yj_destroy(_ url: URL) {
		queue.destroy(url)
	}
	
	public func yj_pauseAll() {
		queue.pauseAll()
	}
	
	public func yj_cancelAll() {
		queue.cancelAll()
	}
	
	public func yj_resumeAll() {
		queue.resumeAll()
	}
	
	public func yj_destroyAll() {
		queue.destroyAll()
	}
}

extension YJDownloaders {
	
}

extension YJDownloaders: URLSessionDataDelegate {
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		if let url = dataTask.originalRequest?.url, let downloader = queue.downloader(forUrl: url) {
			downloader.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
		}
	}
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		if let url = dataTask.originalRequest?.url, let downloader = queue.downloader(forUrl: url) {
			downloader.urlSession(session, dataTask: dataTask, didReceive: data)
		}
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let url = task.originalRequest?.url, let downloader = queue.downloader(forUrl: url) {
			downloader.urlSession(session, task: task, didCompleteWithError: error)
		}
	}
}


fileprivate class YJDownloadersQueue {
	
	var tmpPath: String?
	var cachePath: String?
	
	var maxRunningCount: Int = 3
	
	fileprivate var currentCount: Int {
		return _downloaders.filter { $1.state == .downloading }.count
	}
	
	fileprivate let queue = DispatchQueue(label: "yjdownloads-queue")
	
	fileprivate var _downloaders = [String: YJDownloader]()
	
	fileprivate var session: URLSession?
	
	func reset(_ tmpPath: String? = nil, cachePath: String? = nil) {
		_downloaders.removeAll()
		self.tmpPath = tmpPath
		self.cachePath = cachePath
	}
	
	fileprivate func start() {
		if currentCount >= maxRunningCount {
			return
		}
		
		var count = 0
		_downloaders.filter {
			let r = $1.state == .waitting && count < self.maxRunningCount
			if r {
				count += 1
			}
			return r
		}.forEach { $1.yj_start() }
	}
	
	fileprivate func addDownloader(_ url: URL, destination: String? = nil, stateChanged:((YJDownloaderState)->Void)? = nil, progressChanged:((Double)->Void)? = nil, receiveTotalSize: ((UInt64)->Void)? = nil) {
		queue.sync {
			let urlmd5 = url.absoluteString.md5()
			var downloader = _downloaders[urlmd5]
			if downloader == nil {
				downloader = YJDownloader(session, tmpPath: tmpPath, cachePath: cachePath)
				_downloaders[urlmd5] = downloader
				
				let item = YJDownloaderItem()
				item.url = url
				item.destination = destination
				item.stateChanged = {[weak self] (state: YJDownloaderState) in
					
					switch state {
					case .success, .failed:
						self?._downloaders.removeValue(forKey: urlmd5)
						self?.start()
					case .cancelled, .paused:
						self?.start()
					default:
						break
					}
					stateChanged?(state)
				}
				item.progressChanged = progressChanged
				item.receiveTotalSize = receiveTotalSize
				
				downloader?.yj_download(item, immediately: false)
			}
			downloader?.yj_setWaitting()
			start()
		}
	}
	
	fileprivate func downloader(forUrl url: URL) -> YJDownloader? {
		var downloader: YJDownloader?
		queue.sync {
			let urlmd5 = url.absoluteString.md5()
			downloader = _downloaders[urlmd5]
		}
		return downloader
	}
	
	fileprivate func removeDownloader(forUrl url: URL? = nil) {
		queue.sync {
			if let url = url {
				let urlmd5 = url.absoluteString.md5()
				_downloaders.removeValue(forKey: urlmd5)
			} else {
				_downloaders.removeAll()
			}
		}
	}
	
	fileprivate func pause(_ url: URL) {
		if let downloader = downloader(forUrl: url) {
			downloader.yj_pause()
		}
	}
	
	fileprivate func resume(_ url: URL) {
		
		if let downloader = downloader(forUrl: url) {
			if currentCount >= maxRunningCount && downloader.state.value != YJDownloaderState.downloading.value {
				downloader.yj_setWaitting()
			} else {
				downloader.yj_resume()
			}
		}
	}
	
	fileprivate func cancel(_ url: URL) {
		if let downloader = downloader(forUrl: url) {
			downloader.yj_cancel()
			removeDownloader(forUrl: url)
		}
	}
	
	fileprivate func destroy(_ url: URL) {
		if let downloader = downloader(forUrl: url) {
			downloader.yj_destroy()
			removeDownloader(forUrl: url)
		}
	}
	
	fileprivate func pauseAll() {
		_downloaders.forEach{ $1.yj_pause() }
	}
	
	fileprivate func cancelAll() {
		_downloaders.forEach{
			$1.yj_cancel()
		}
		removeDownloader()
	}
	
	fileprivate func resumeAll() {
		_downloaders.forEach{ $1.yj_resume() }
	}
	
	fileprivate func destroyAll() {
		_downloaders.forEach{
			$1.yj_destroy()
		}
		removeDownloader()
	}
}

extension YJDownloadersQueue {
	convenience init(_ session: URLSession?) {
		self.init()
		self.session = session
	}
}












