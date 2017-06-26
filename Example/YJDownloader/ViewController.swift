//
//  ViewController.swift
//  YJDownloader
//
//  Created by Zyj163 on 06/23/2017.
//  Copyright (c) 2017 Zyj163. All rights reserved.
//

import UIKit
import Foundation
import YJDownloader

class ViewController: UIViewController {

	@IBOutlet weak var progress: UIProgressView!
	
	let downloaders = YJDownloaders.downloaders
	
	let url = URL(string: "http://160721.142.unicom.data.tv002.com:443/down/24ac8168eba1a6efe85400518eacc8ae-14080607/CloudMounter10%20Cr%20.dmg?cts=wt-f-D211A144A1A50&ctp=211A144A1A50&ctt=1498209275&limit=1&spd=200000&ctk=249a11509563164a52f6b530aee2db7a&chk=24ac8168eba1a6efe85400518eacc8ae-14080607")!
	
	let url2 = URL(string: "http://211.94.109.18:9999/sw.bos.baidu.com/sw-search-sp/software/447feea06f61e/QQ_mac_5.5.1.dmg")!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		downloaders.maxRunningCount = 1
    }
	
	@IBOutlet weak var download: UIButton!
	
	@IBAction func download(_ sender: Any) {
		
		downloaders.yj_download(url, stateChanged: { (state: YJDownloaderState) in
			switch state {
			case .paused(let downloadingPath, let downloadedPath):
				print("pause, thread: \(Thread.current), downloadingPath: \(downloadingPath), downloadedPath: \(downloadedPath)")
			case .downloading:
				print("downloading, thread: \(Thread.current)")
			case .success(let filePath):
				print("success, thread: \(Thread.current), filePath: \(filePath)")
			case .failed(let error):
				print("failed, thread: \(Thread.current), error: \(String(describing: error))")
			case .cancelled(let downloadingPath, let downloadedPath):
				print("cancelled, thread: \(Thread.current), downloadingPath: \(downloadingPath), downloadedPath: \(downloadedPath)")
			default:
				print("unknown, thread: \(Thread.current)")
			}
		}, progressChanged: {[weak self] (progress: Double) in
			print("progress:\(progress), thread: \(Thread.current)")
			DispatchQueue.main.async {
				self?.progress.progress = Float(progress)
			}
		}) { (totalSize: UInt64) in
			print("totalSize: \(totalSize), thread: \(Thread.current)")
		}
	}
	@IBOutlet weak var pause: UIButton!

	@IBAction func pause(_ sender: Any) {
		downloaders.yj_pause(url)
	}
	@IBAction func cancel(_ sender: Any) {
		downloaders.yj_cancel(url)
	}
	@IBAction func resume(_ sender: Any) {
		downloaders.yj_resume(url)
	}
	@IBAction func remove(_ sender: Any) {
		downloaders.yj_removeTmpFiles([url])
	}
	@IBAction func removecache(_ sender: Any) {
		downloaders.yj_removeCacheFiles([url])
	}
	
	
	
	@IBOutlet weak var progress2: UIProgressView!
	@IBAction func download2(_ sender: Any) {
		
		downloaders.yj_download(url2, stateChanged: { (state: YJDownloaderState) in
			switch state {
			case .paused(let downloadingPath, let downloadedPath):
				print("pause, thread: \(Thread.current), downloadingPath: \(downloadingPath), downloadedPath: \(downloadedPath)")
			case .downloading:
				print("downloading, thread: \(Thread.current)")
			case .success(let filePath):
				print("success, thread: \(Thread.current), filePath: \(filePath)")
			case .failed(let error):
				print("failed, thread: \(Thread.current), error: \(String(describing: error))")
			case .cancelled(let downloadingPath, let downloadedPath):
				print("cancelled, thread: \(Thread.current), downloadingPath: \(downloadingPath), downloadedPath: \(downloadedPath)")
			default:
				print("unknown, thread: \(Thread.current)")
			}
		}, progressChanged: {[weak self] (progress: Double) in
			print("progress:\(progress), thread: \(Thread.current)")
			DispatchQueue.main.async {
				self?.progress2.progress = Float(progress)
			}
		}) { (totalSize: UInt64) in
			print("totalSize: \(totalSize), thread: \(Thread.current)")
		}
	}
	
	@IBAction func pause2(_ sender: Any) {
		downloaders.yj_pause(url2)
	}
	@IBAction func cancel2(_ sender: Any) {
		downloaders.yj_cancel(url2)
	}
	@IBAction func resume2(_ sender: Any) {
		downloaders.yj_resume(url2)
	}
	@IBAction func remove2(_ sender: Any) {
		downloaders.yj_removeTmpFiles([url2])
	}
	@IBAction func removecache2(_ sender: Any) {
		downloaders.yj_removeCacheFiles([url2])
	}
	
	
	@IBAction func remove_tmp(_ sender: Any) {
		downloaders.yj_removeTmp()
	}
	
	@IBAction func remove_cache(_ sender: Any) {
		downloaders.yj_removeCache()
	}
	
}

